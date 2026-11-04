import React from 'react';
import { beforeEach, afterEach, describe, expect, it, vi } from 'vitest';
import { cleanup, fireEvent, render, screen, waitFor } from '@testing-library/react';
import { confirmSignIn, fetchAuthSession, getCurrentUser, signIn, signOut } from 'aws-amplify/auth';
import App from './App.jsx';

vi.mock('aws-amplify/auth', () => ({ confirmSignIn: vi.fn(), fetchAuthSession: vi.fn(), getCurrentUser: vi.fn(), signIn: vi.fn(), signOut: vi.fn() }));
const user = { username: 'tester', signInDetails: { loginId: 'test@example.com' } };
beforeEach(() => {
  vi.resetAllMocks();
  getCurrentUser.mockRejectedValue(new Error('signed out'));
  fetchAuthSession.mockResolvedValue({ tokens: { accessToken: { toString: () => 'access-token' } } });
  vi.stubGlobal('fetch', vi.fn());
});
afterEach(() => { cleanup(); vi.unstubAllGlobals(); });
async function openChat() {
  getCurrentUser.mockResolvedValue(user);
  render(<App apiUrl="https://example.com/chat" />);
  return screen.findByLabelText('Ask a question');
}

describe('workspace', () => {
  it('shows configuration help before attempting auth', () => {
    render(<App configured={false} />);
    expect(screen.getByText('Connect your workspace')).toBeInTheDocument();
    expect(getCurrentUser).not.toHaveBeenCalled();
  });
  it('signs in with SRP and opens the chat', async () => {
    render(<App apiUrl="https://example.com/chat" />);
    fireEvent.change(await screen.findByLabelText('Work email'), { target: { value: 'test@example.com' } });
    fireEvent.change(screen.getByLabelText('Password'), { target: { value: 'secret' } });
    signIn.mockResolvedValue({ isSignedIn: true });
    getCurrentUser.mockResolvedValue(user);
    fireEvent.click(screen.getByRole('button', { name: 'Sign in' }));
    expect(await screen.findByLabelText('Ask a question')).toBeInTheDocument();
    expect(signIn).toHaveBeenCalledWith(expect.objectContaining({ options: { authFlowType: 'USER_SRP_AUTH' } }));
  });
  it('handles a required new password', async () => {
    render(<App apiUrl="https://example.com/chat" />);
    fireEvent.change(await screen.findByLabelText('Work email'), { target: { value: 'test@example.com' } });
    fireEvent.change(screen.getByLabelText('Password'), { target: { value: 'temporary' } });
    signIn.mockResolvedValue({ isSignedIn: false, nextStep: { signInStep: 'CONFIRM_SIGN_IN_WITH_NEW_PASSWORD_REQUIRED' } });
    fireEvent.click(screen.getByRole('button', { name: 'Sign in' }));
    fireEvent.change(await screen.findByLabelText('New password'), { target: { value: 'PermanentPass123!' } });
    fireEvent.change(screen.getByLabelText('Confirm new password'), { target: { value: 'PermanentPass123!' } });
    confirmSignIn.mockResolvedValue({ isSignedIn: true });
    getCurrentUser.mockResolvedValue(user);
    fireEvent.click(screen.getByRole('button', { name: 'Set password & continue' }));
    expect(await screen.findByLabelText('Ask a question')).toBeInTheDocument();
    expect(confirmSignIn).toHaveBeenCalledWith({ challengeResponse: 'PermanentPass123!' });
  });
  it('sends only the question with the access token and displays sources', async () => {
    const input = await openChat();
    fetch.mockResolvedValue({ ok: true, status: 200, json: async () => ({ answer: 'RTO is 60 minutes.', sources: ['s3://example/disaster-recovery-policy.md'] }) });
    fireEvent.change(input, { target: { value: 'What is the RTO?' } });
    fireEvent.click(screen.getByRole('button', { name: 'Send question' }));
    expect(await screen.findByText('RTO is 60 minutes.')).toBeInTheDocument();
    expect(screen.getByText('disaster-recovery-policy.md')).toBeInTheDocument();
    expect(fetch).toHaveBeenCalledWith('https://example.com/chat', expect.objectContaining({
      headers: { 'Content-Type': 'application/json', Authorization: 'Bearer access-token' },
      body: JSON.stringify({ question: 'What is the RTO?' }),
    }));
    fireEvent.click(screen.getByRole('button', { name: /New conversation/ }));
    expect(screen.queryByText('RTO is 60 minutes.')).not.toBeInTheDocument();
  });
  it('preserves the question on failure and allows retry', async () => {
    const input = await openChat();
    fetch.mockResolvedValue({ ok: false, status: 502 });
    fireEvent.change(input, { target: { value: 'Recovery?' } });
    fireEvent.click(screen.getByRole('button', { name: 'Send question' }));
    expect(await screen.findByRole('alert')).toHaveTextContent('couldn’t retrieve');
    expect(input).toHaveValue('Recovery?');
    expect(screen.getByRole('button', { name: 'Send question' })).toBeEnabled();
  });
  it('reports an expired session', async () => {
    const input = await openChat();
    fetch.mockResolvedValue({ ok: false, status: 401 });
    fireEvent.change(input, { target: { value: 'Recovery?' } });
    fireEvent.click(screen.getByRole('button', { name: 'Send question' }));
    expect(await screen.findByRole('alert')).toHaveTextContent('Sign out and sign in again');
  });
  it('clears the workspace on sign out', async () => {
    await openChat(); signOut.mockResolvedValue();
    fireEvent.click(screen.getByRole('button', { name: 'Sign out' }));
    expect(await screen.findByLabelText('Work email')).toBeInTheDocument();
    expect(signOut).toHaveBeenCalledOnce();
  });
  it('ignores an answer that arrives after sign out', async () => {
    const input = await openChat();
    let resolveRequest;
    fetch.mockReturnValue(new Promise(resolve => { resolveRequest = resolve; }));
    fireEvent.change(input, { target: { value: 'RTO?' } });
    fireEvent.click(screen.getByRole('button', { name: 'Send question' }));
    await waitFor(() => expect(fetch).toHaveBeenCalledOnce());
    signOut.mockResolvedValue();
    fireEvent.click(screen.getByRole('button', { name: 'Sign out' }));
    await screen.findByLabelText('Work email');
    resolveRequest({ ok: true, status: 200, json: async () => ({ answer: 'Late private answer', sources: [] }) });
    await waitFor(() => expect(screen.queryByText('Late private answer')).not.toBeInTheDocument());
  });
});
