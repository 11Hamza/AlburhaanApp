/**
 * Al-Burhaan Library Backend API
 * Home page showing API documentation
 */

export default function Home() {
  const endpoints = [
    { method: 'GET', path: '/api/health', description: 'Health check endpoint' },
    { method: 'POST', path: '/api/auth/login', description: 'Login with library card' },
    { method: 'POST', path: '/api/auth/guest', description: 'Get guest session' },
    { method: 'POST', path: '/api/auth/logout', description: 'Logout' },
    { method: 'POST', path: '/api/auth/refresh', description: 'Refresh token' },
    { method: 'GET', path: '/api/books', description: 'List all books' },
    { method: 'GET', path: '/api/books/:id', description: 'Get book details' },
    { method: 'GET', path: '/api/books/:id/availability', description: 'Check book availability' },
    { method: 'GET', path: '/api/books/search', description: 'Advanced book search' },
    { method: 'GET', path: '/api/filters/subjects', description: 'Get subject filters' },
    { method: 'GET', path: '/api/filters/classifications', description: 'Get classification filters' },
    { method: 'GET', path: '/api/filters/languages', description: 'Get language filters' },
    { method: 'GET', path: '/api/libraries', description: 'List all libraries' },
    { method: 'GET', path: '/api/libraries/:id', description: 'Get library details' },
    { method: 'GET', path: '/api/user/profile', description: 'Get user profile' },
    { method: 'PUT', path: '/api/user/profile', description: 'Update preferences' },
    { method: 'GET', path: '/api/user/card', description: 'Get digital library card' },
    { method: 'GET', path: '/api/user/summary', description: 'Get account summary' },
    { method: 'GET', path: '/api/loans', description: 'Get current loans' },
    { method: 'GET', path: '/api/loans/history', description: 'Get loan history' },
    { method: 'POST', path: '/api/loans/:id/renew', description: 'Renew a loan' },
    { method: 'POST', path: '/api/loans/renew-all', description: 'Renew all loans' },
    { method: 'GET', path: '/api/holds', description: 'Get current holds' },
    { method: 'POST', path: '/api/holds', description: 'Place a hold' },
    { method: 'DELETE', path: '/api/holds/:id', description: 'Cancel a hold' },
    { method: 'GET', path: '/api/favorites', description: 'Get favorites' },
    { method: 'POST', path: '/api/favorites', description: 'Add to favorites' },
    { method: 'DELETE', path: '/api/favorites/:id', description: 'Remove from favorites' },
  ];

  return (
    <div className="min-h-screen bg-gradient-to-b from-gray-900 to-gray-800 text-white p-8">
      <div className="max-w-4xl mx-auto">
        <header className="text-center mb-12">
          <h1 className="text-4xl font-bold mb-4">Al-Burhaan Library API</h1>
          <p className="text-gray-400 text-lg">
            Backend API for the Al-Burhaan Library Mobile Application
          </p>
          <div className="mt-4 flex justify-center gap-4">
            <span className="px-3 py-1 bg-green-600 rounded-full text-sm">v1.0.0</span>
            <span className="px-3 py-1 bg-blue-600 rounded-full text-sm">Next.js</span>
            <span className="px-3 py-1 bg-purple-600 rounded-full text-sm">Koha Integration</span>
          </div>
        </header>

        <section className="mb-12">
          <h2 className="text-2xl font-semibold mb-6 border-b border-gray-700 pb-2">
            API Endpoints
          </h2>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="text-left text-gray-400 border-b border-gray-700">
                  <th className="py-3 px-4">Method</th>
                  <th className="py-3 px-4">Endpoint</th>
                  <th className="py-3 px-4">Description</th>
                </tr>
              </thead>
              <tbody>
                {endpoints.map((endpoint, index) => (
                  <tr key={index} className="border-b border-gray-800 hover:bg-gray-800/50">
                    <td className="py-3 px-4">
                      <span className={`px-2 py-1 rounded text-xs font-mono ${
                        endpoint.method === 'GET' ? 'bg-green-700' :
                        endpoint.method === 'POST' ? 'bg-blue-700' :
                        endpoint.method === 'PUT' ? 'bg-yellow-700' :
                        endpoint.method === 'PATCH' ? 'bg-orange-700' :
                        'bg-red-700'
                      }`}>
                        {endpoint.method}
                      </span>
                    </td>
                    <td className="py-3 px-4 font-mono text-sm text-gray-300">
                      {endpoint.path}
                    </td>
                    <td className="py-3 px-4 text-gray-400">
                      {endpoint.description}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>

        <section className="mb-12">
          <h2 className="text-2xl font-semibold mb-6 border-b border-gray-700 pb-2">
            Authentication
          </h2>
          <div className="bg-gray-800 rounded-lg p-6">
            <p className="text-gray-300 mb-4">
              Most endpoints require authentication via JWT Bearer token.
            </p>
            <div className="bg-gray-900 p-4 rounded font-mono text-sm">
              <span className="text-gray-500">Header:</span>{' '}
              <span className="text-green-400">Authorization: Bearer {'<token>'}</span>
            </div>
          </div>
        </section>

        <section className="mb-12">
          <h2 className="text-2xl font-semibold mb-6 border-b border-gray-700 pb-2">
            Quick Start
          </h2>
          <div className="space-y-4">
            <div className="bg-gray-800 rounded-lg p-4">
              <p className="text-gray-400 mb-2">1. Get a guest token:</p>
              <code className="text-green-400 text-sm">
                POST /api/auth/guest
              </code>
            </div>
            <div className="bg-gray-800 rounded-lg p-4">
              <p className="text-gray-400 mb-2">2. Or login with library card:</p>
              <code className="text-green-400 text-sm">
                {`POST /api/auth/login { "cardNumber": "...", "password": "..." }`}
              </code>
            </div>
            <div className="bg-gray-800 rounded-lg p-4">
              <p className="text-gray-400 mb-2">3. Browse books:</p>
              <code className="text-green-400 text-sm">
                GET /api/books?page=1&per_page=10
              </code>
            </div>
          </div>
        </section>

        <footer className="text-center text-gray-500 text-sm">
          <p>Al-Burhaan Library - Connecting Knowledge</p>
          <p className="mt-2">
            <a href="/api/health" className="text-blue-400 hover:underline">
              Check API Health
            </a>
          </p>
        </footer>
      </div>
    </div>
  );
}
