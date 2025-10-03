import React from 'react';
import {createRoot} from 'react-dom/client';
import App from './App';
const el=document.getElementById('root')||document.createElement('div'); el.id='root'; document.body.appendChild(el);
createRoot(el).render(<App/>);
