# Usa l'immagine ufficiale NVIDIA per JetPack 5.1.x come base
FROM nvcr.io/nvidia/l4t-pytorch:r35.2.1-pth2.0-py3

# 1. Installazione Node.js 20 e NPM usando lo script ufficiale Nodesource (Versione Blindata)
RUN apt-get update && apt-get install -y curl ca-certificates gnupg \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*
    
# Verifica che npm sia presente (se fallisce qui, il build si ferma subito con errore chiaro)
RUN node -v && npm -v

# 2. Il resto resta uguale...
COPY --from=ghcr.io/astral-sh/uv:0.9.26 /uv /uvx /bin/

WORKDIR /app

# 3. Copia dei file di dipendenza per sfruttare la cache di Docker
COPY package.json package-lock.json ./
COPY frontend/package.json frontend/package-lock.json ./frontend/
COPY backend/pyproject.toml backend/uv.lock ./backend/

# 4. Installazione dipendenze Frontend e Backend
# Usiamo --unsafe-perm per evitare problemi di permessi con npm su Docker
RUN npm ci --unsafe-perm \
    && npm ci --prefix frontend --unsafe-perm

# Installazione Python 3.11 e sync delle dipendenze via uv
# Configura uv per usare l'architettura corretta del nanetto (ARM64)
RUN cd backend && uv python install 3.11 && uv sync

# 5. Copia del resto del codice sorgente
COPY . .

# 6. Esposizione porte (3000: Frontend, 5001: Backend API)
EXPOSE 3000 5001

# Avvio in modalità sviluppo (npm run dev gestisce entrambi i processi)
CMD ["npm", "run", "dev"]
