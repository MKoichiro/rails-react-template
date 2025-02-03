import { useState } from 'react'
import reactLogo from './assets/react.svg'
import viteLogo from '/vite.svg'
import './App.css'

function App() {
  const [count, setCount] = useState(0)

  const [users, setUsers] = useState<string>()
  const btnClickHandler = async () => {
    console.table(import.meta.env);

    // 環境ごとにAPIエンドポイントを設定
    const apiUrl = import.meta.env.PROD
      ? "/api/v1/users"                             // 本番環境用URL
      : `${import.meta.env.VITE_API_SERVER}/users`; // 開発環境用URL

    console.log(`Fetching from: ${apiUrl}`);
  
    try {
      const response = await fetch(apiUrl, { mode: 'cors' });
      if (response.ok) {
        const data = await response.json();
        console.log('data', data);
        setUsers(JSON.stringify(data));
      } else {
        console.error('API error:', response.statusText);
      }
    } catch (error) {
      console.error('Fetch error:', error);
    }
  }

  return (
    <>
      <div>
        <a href="https://vite.dev" target="_blank">
          <img src={viteLogo} className="logo" alt="Vite logo" />
        </a>
        <a href="https://react.dev" target="_blank">
          <img src={reactLogo} className="logo react" alt="React logo" />
        </a>
      </div>
      <h1>Vite + React</h1>
      <div className="card">
        <button onClick={() => setCount((count) => count + 1)}>
          count is {count}
        </button>
        <button onClick={btnClickHandler}>
          Call API
        </button>
        <p>
          <code>import.meta.env.VITE_API_SERVER/users</code>: {users}
        </p>
      </div>
      <p className="read-the-docs">
        Click on the Vite and React logos to learn more
      </p>
    </>
  )
}

export default App
