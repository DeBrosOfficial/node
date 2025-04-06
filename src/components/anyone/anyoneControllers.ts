import { Request, Response } from 'express';
import { SocksProxyAgent } from 'socks-proxy-agent';

export class AnyoneController {
  public async proxy(req: Request, res: Response, socksClient: any): Promise<void> {
    try {
      if (!socksClient) {
        throw new Error('Anyone Network not initialized');
      }

      const { url, method, headers, body } = req.body;

      if (!url) {
        res.status(400).json({ error: 'URL is required' });
      }

      console.log(`📡 Proxying request to: ${url}`);

      // Create the SOCKS agent
      const socksAgent = new SocksProxyAgent(`socks5h://127.0.0.1:${socksClient.socksPort}`);

      // Special handling for Supabase requests
      const requestHeaders = { ...headers };
      const targetUrl = url;
      const processedBody = body;

      // Prepare fetch options
      const fetchOptions = {
        method: method || 'GET',
        agent: socksAgent,
        headers: requestHeaders,
        body: body,
      };

      // Add body if it exists and method is not GET
      if (processedBody && method !== 'GET' && method !== 'DELETE') {
        fetchOptions.body = processedBody;
      }

      console.log(`📡 Request details:`, {
        url: targetUrl,
        method: fetchOptions.method,
        hasBody: !!fetchOptions.body,
        headers: Object.keys(fetchOptions.headers),
      });

      // Execute the request
      const response = await fetch(targetUrl, fetchOptions);

      // Get response headers
      const responseHeaders = Object.fromEntries(response.headers.entries());

      // Get response data based on content type
      const contentType = response.headers.get('content-type') || '';
      let responseData;

      if (contentType.includes('application/json')) {
        try {
          responseData = await response.json();
        } catch (e: any) {
          // If JSON parsing fails, fallback to text
          const textData = await response.text();
          console.warn('Failed to parse JSON response, returning as text:', e.message);
          responseData = textData;
        }
      } else {
        responseData = await response.text();
        // Try to parse as JSON anyway in case Content-Type is wrong
        try {
          responseData = JSON.parse(responseData);
        } catch (_e) {
          // Keep as text if parsing fails
        }
      }

      // Return the response with all details
      res.json({
        success: true,
        status: response.status,
        statusText: response.statusText,
        headers: responseHeaders,
        response: responseData,
      });
    } catch (error: any) {
      console.error('Proxy error:', error);
      res.status(500).json({
        success: false,
        error: error.message || 'Error proxying request',
      });
    }
  }
}
