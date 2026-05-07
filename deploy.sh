#!/bin/bash
# Anceps Cloud Deployment Script (Slopn't Edition)

set -e

PROJECT_ID=$(gcloud config get-value project)
SERVICE_NAME="anceps-inference"
REGION="us-central1"
BUCKET_NAME="${PROJECT_ID}-anceps-renderer"

echo "🚀 Starting Anceps Deployment for project: $PROJECT_ID"

# 1. Enable APIs
echo "📡 Enabling Google Cloud APIs..."
gcloud services enable \
    run.googleapis.com \
    artifactregistry.googleapis.com \
    cloudbuild.googleapis.com \
    storage.googleapis.com

# 2. Build and Deploy Inference to Cloud Run
echo "📦 Building and Deploying Inference Engine..."
IMAGE_PATH="us-central1-docker.pkg.dev/$PROJECT_ID/anceps/inference"

# Using Cloud Build with a config file
gcloud builds submit --config cloudbuild.yaml .

gcloud run deploy $SERVICE_NAME \
    --image $IMAGE_PATH \
    --platform managed \
    --region $REGION \
    --allow-unauthenticated \
    --memory 8Gi \
    --cpu 4 \
    --timeout 300 \
    --set-env-vars="MODEL_NAME=dummy,API_KEY=dev-key"

# Get the URL of the deployed service
BACKEND_URL=$(gcloud run services describe $SERVICE_NAME --platform managed --region $REGION --format 'value(status.url)')
echo "✅ Backend deployed at: $BACKEND_URL"

# 3. Deploy Renderer to GCS
echo "🌐 Deploying Renderer to Google Cloud Storage..."
if ! gsutil ls -b gs://$BUCKET_NAME > /dev/null 2>&1; then
    gsutil mb -l $REGION gs://$BUCKET_NAME
fi

# Set bucket to public-read for static website hosting
gsutil iam ch allUsers:objectViewer gs://$BUCKET_NAME
gsutil web set -m index.html -e index.html gs://$BUCKET_NAME

# Upload renderer files
gsutil cp renderer/index.html gs://$BUCKET_NAME/index.html

echo "✅ Renderer deployed at: http://storage.googleapis.com/$BUCKET_NAME/index.html?backend=$BACKEND_URL"

echo "──────────────────────────────────────────"
echo "🎉 DEPLOYMENT COMPLETE"
echo "Backend:  $BACKEND_URL"
echo "Frontend: http://storage.googleapis.com/$BUCKET_NAME/index.html?backend=$BACKEND_URL"
echo "──────────────────────────────────────────"
echo "💡 To use with your local SuperCollider/Octave stack:"
echo "   Update your INFERENCE_URL to $BACKEND_URL"
