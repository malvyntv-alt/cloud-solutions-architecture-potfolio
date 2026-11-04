"""Render the deployed DEV architecture as PNG and self-contained SVG.

Requires Pillow. Run from any working directory. Icon provenance: README.md.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
from html import escape
import base64
import math

ROOT = Path(__file__).resolve().parent
W, H = 1800, 1300
canvas = Image.new('RGB', (W, H), 'white')
draw = ImageDraw.Draw(canvas)
svg = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">', '<rect width="100%" height="100%" fill="white"/>']
NAVY, GRAY, BLUE, GREEN = '#142b4b', '#50647b', '#2563a6', '#278263'


def font(size, bold=False):
    directory = Path('C:/Windows/Fonts')
    name = directory / ('arialbd.ttf' if bold else 'arial.ttf')
    return ImageFont.truetype(str(name), size) if name.exists() else ImageFont.truetype('DejaVuSans.ttf', size)


def text(x, y, value, size=22, color=NAVY, bold=False, center=False):
    f = font(size, bold)
    if center:
        x -= draw.textlength(value, font=f) / 2
    draw.text((x, y), value, fill=color, font=f)
    svg.append(f'<text x="{x}" y="{y + size * .91}" font-family="Arial,sans-serif" font-size="{size}" font-weight="{700 if bold else 400}" fill="{color}">{escape(value)}</text>')


def box(x, y, w, h, fill='white', stroke='#c9d7e6', radius=15):
    draw.rounded_rectangle((x, y, x+w, y+h), radius, fill=fill, outline=stroke, width=2)
    svg.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{radius}" fill="{fill}" stroke="{stroke}" stroke-width="2"/>')


def line(points, color=BLUE, dashed=False, arrow=True):
    for a, b in zip(points, points[1:]):
        if dashed:
            length = math.dist(a,b)
            for d in range(0, int(length), 16):
                e=min(d+9,length)
                draw.line((a[0]+(b[0]-a[0])*d/length,a[1]+(b[1]-a[1])*d/length,a[0]+(b[0]-a[0])*e/length,a[1]+(b[1]-a[1])*e/length),fill=color,width=3)
        else:
            draw.line((a,b), fill=color, width=3)
    pts=' '.join(f'{x},{y}' for x,y in points)
    dash=' stroke-dasharray="9 7"' if dashed else ''
    svg.append(f'<polyline points="{pts}" fill="none" stroke="{color}" stroke-width="3"{dash}/>')
    if arrow:
        a,b=points[-2:]; angle=math.atan2(b[1]-a[1],b[0]-a[0]);tip=[b]+[(b[0]-14*math.cos(angle+t),b[1]-14*math.sin(angle+t)) for t in (-.45,.45)]
        draw.polygon(tip,fill=color)
        svg.append(f'<polygon points="{" ".join(f"{x},{y}" for x,y in tip)}" fill="{color}"/>')


def icon(x,y,key,size=65):
    path=ROOT/'icons'/f'{key}.png'
    im=Image.open(path).convert('RGBA').resize((size,size),Image.Resampling.LANCZOS)
    canvas.paste(im,(x,y),im)
    data=base64.b64encode(path.read_bytes()).decode()
    svg.append(f'<image x="{x}" y="{y}" width="{size}" height="{size}" href="data:image/png;base64,{data}"/>')


def service(x,y,key,title,subtitle,detail=None):
    box(x,y,270,170)
    if key:
        icon(x+102,y+16,key)
    else:
        box(x+107,y+21,56,43,'#edf3fa',BLUE,5)
        line([(x+116,y+73),(x+154,y+73)],arrow=False)
    text(x+135,y+91,title,21,bold=True,center=True)
    text(x+135,y+122,subtitle,18,color=GRAY,center=True)
    if detail:
        detail_size = 16
        while draw.textlength(detail, font=font(detail_size)) > 250:
            detail_size -= 1
        text(x+135,y+145,detail,detail_size,color=GRAY,center=True)


text(50,30,'EnterpriseIQ | Authenticated serverless RAG',42,bold=True)
text(50,90,'Deployed DEV design · us-east-1 · synthetic policy corpus · November 3, 2026',23,color=GRAY)
box(30,150,1740,245,'#f6f9fe')
text(55,169,'01  IDENTITY & BROWSER DELIVERY',22,bold=True)
service(65,210,'amplify','AWS Amplify','React / Vite static hosting')
service(405,210,None,'Browser / React app','Invite-only workspace')
service(745,210,'cognito','Amazon Cognito','SRP sign-in / public client')
line([(335,295),(405,295)])
line([(675,295),(745,295)])
text(1070,227,'Sign-in returns an access token to the browser.',24,bold=True)
text(1070,271,'Session storage · no browser AWS credentials',21,color=GRAY)
text(1070,312,'Cognito JWT protects POST /chat.',22,color=GRAY)
text(1070,346,'CORS permits the exact hosted origin.',21,color=GRAY)
box(30,425,1740,280,'#f4f8fd')
text(55,444,'02  QUESTION & ANSWER',22,bold=True)
service(405,495,'api','Amazon API Gateway','HTTP API / JWT authorizer')
service(850,495,'lambda','AWS Lambda','Python Retrieve + Converse','No VPC · stateless requests')
service(1455,495,'bedrock','Amazon Bedrock','Amazon Nova Lite','Context + question → answer')
line([(540,380),(540,495)])
text(560,398,'HTTPS + access token',18)
line([(675,577),(850,577)])
text(762,539,'Validated input',18,center=True)
line([(1120,577),(1455,577)])
text(1287,536,'Converse',19,center=True)
text(1287,605,'Answer returned via Lambda / API',17,center=True,color=GRAY)
box(30,755,1740,280,'#f4faf6', '#a9cdb8')
text(55,774,'03  DOCUMENT INGESTION & KNOWLEDGE RETRIEVAL',22,bold=True,color=GREEN)
service(65,835,'s3','Amazon S3','Private synthetic policies','sample-knowledge-base/ prefix')
service(405,835,'bedrock','Amazon Bedrock','Titan Embeddings v2','Ingestion embeddings')
service(850,835,'bedrock','Bedrock Knowledge Base','VECTOR retrieval','Retrieve top 5 context results')
service(1455,835,'vectors','Amazon S3 Vectors','Vector bucket + index','1024 dimensions · cosine distance')
line([(335,920),(405,920)],color=GREEN,dashed=True)
line([(675,920),(850,920)],color=GREEN,dashed=True)
line([(1120,945),(1455,945)],color=GREEN,dashed=True)
text(1287,963,'Ingestion writes vectors',17,color=GREEN,center=True)
line([(1120,882),(1455,882)])
text(1287,845,'Query vector index',18,center=True)
line([(985,665),(985,835)])
text(1010,714,'Retrieve / context + source locations',20)
box(30,1065,1740,115,'#f8fafc')
icon(55,1090,'iam',56);text(125,1085,'Scoped IAM',21,bold=True);text(125,1120,'Knowledge Base / model access',19,color=GRAY)
icon(535,1090,'cloudwatch',56);text(605,1085,'Amazon CloudWatch',21,bold=True);text(605,1120,'API + Lambda logs · 14-day retention',19,color=GRAY)
text(1140,1085,'Terraform · separate DEV / PROD roots',21,bold=True)
text(1140,1120,'No VPC, NAT or private endpoints',19,color=GRAY)
text(50,1200,'Blue: request / retrieval flow     Green dashed: document ingestion     Responses return along the request path.',20,color=GRAY)
text(50,1235,'DEV scope: WAF disabled · no persistent chat history · no tenant/document isolation · references are not verified citations.',20,color=GRAY)
canvas.save(ROOT/'enterpriseiq-aws-architecture.png')
svg.append('</svg>')
(ROOT/'enterpriseiq-aws-architecture.svg').write_text('\n'.join(svg),encoding='utf-8')
print('Rendered enterpriseiq-aws-architecture.png and .svg')
