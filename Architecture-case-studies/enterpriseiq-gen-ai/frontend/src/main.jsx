import React from 'react';
import { createRoot } from 'react-dom/client';
import { Amplify } from 'aws-amplify';
import { cognitoUserPoolsTokenProvider } from 'aws-amplify/auth/cognito';
import { sessionStorage } from 'aws-amplify/utils';
import App from './App.jsx';
import './styles.css';

const pool = import.meta.env.VITE_USER_POOL_ID;
const client = import.meta.env.VITE_USER_POOL_CLIENT_ID;
const api = import.meta.env.VITE_CHAT_API_URL;
const configured = Boolean(pool && client && api?.startsWith('https://'));
if (configured) {
  Amplify.configure({ Auth: { Cognito: { userPoolId: pool, userPoolClientId: client } } });
  cognitoUserPoolsTokenProvider.setKeyValueStorage(sessionStorage);
}
createRoot(document.getElementById('root')).render(
  <React.StrictMode><App configured={configured} apiUrl={api} /></React.StrictMode>,
);
