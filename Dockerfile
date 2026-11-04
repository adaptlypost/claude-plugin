FROM node:22-alpine
RUN npm install -g mcp-remote@0.1.49
ENTRYPOINT ["mcp-remote", "https://mcp.adaptlypost.com/mcp"]
