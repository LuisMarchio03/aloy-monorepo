# NLP Service (Python)
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY modules/nlp/requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Download spaCy model
RUN python -m spacy download pt_core_news_sm

# Copy application code
COPY modules/nlp/ ./

# Create logs directory
RUN mkdir -p logs

# Expose port
EXPOSE 8001

# Set environment variables
ENV PYTHONPATH=/app
ENV PORT=8001

# Run the application
CMD ["python", "run.py"]
