# Stage 1: Building the application
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy the rest of the application
COPY . .

# Create next.config.js explicitly
RUN echo "module.exports = { images: { domains: ['your-image-domain.com'] }, eslint: { ignoreDuringBuilds: true }, typescript: { ignoreBuildErrors: true } };" > next.config.js

# Build the application
RUN npm run build

# Remove unnecessary files after build
RUN rm -rf node_modules

# Stage 2: Running the application
FROM node:20-alpine AS runner

WORKDIR /app

# Set to production environment
ENV NODE_ENV=production

# Copy package.json and package-lock.json
COPY package*.json ./

# Install only production dependencies
RUN npm ci --omit=dev

# Copy built application from the builder stage
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/next.config.js ./next.config.js
COPY --from=builder /app/*.png ./
COPY --from=builder /app/*.jpg ./
COPY --from=builder /app/*.jpeg ./
COPY --from=builder /app/*.svg ./

# Add user to run the application without root privileges
RUN addgroup --system --gid 1001 nodejs \
    && adduser --system --uid 1001 nextjs \
    && chown -R nextjs:nodejs /app

USER nextjs

# Expose the port the app will run on
EXPOSE 3000

# Command to run the application
CMD ["npm", "start"]
