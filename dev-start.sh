#!/bin/bash
# Quick start script for development/testing

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}======================================"
echo "Bedside Clock Development Setup"
echo -e "======================================${NC}"
echo ""

# Check if .env exists
if [ ! -f .env ]; then
    echo -e "${YELLOW}Creating .env file from template...${NC}"
    cp .env.example .env
    echo ""
    echo -e "${YELLOW}Please edit .env and add your Home Assistant details:${NC}"
    echo "  nano .env"
    echo ""
    echo "Then run this script again."
    exit 0
fi

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    echo -e "${YELLOW}docker-compose not found. Trying 'docker compose'...${NC}"
    DOCKER_COMPOSE="docker compose"
else
    DOCKER_COMPOSE="docker-compose"
fi

# Start services
echo -e "${GREEN}Starting Docker services...${NC}"
$DOCKER_COMPOSE up -d

echo ""
echo -e "${GREEN}======================================"
echo "Services Started!"
echo -e "======================================${NC}"
echo ""
echo "Access the application:"
echo "  • Production UI:    http://localhost:3000"
echo "  • Development UI:   http://localhost:3001 (with hot reload)"
echo ""
echo "Useful commands:"
echo "  • View logs:        $DOCKER_COMPOSE logs -f"
echo "  • Restart service:  $DOCKER_COMPOSE restart SERVICE_NAME"
echo "  • Stop all:         $DOCKER_COMPOSE down"
echo "  • Trigger wake:     docker exec \$(docker ps -qf 'name=wakeword-mock') touch /app/config/.wake_detected"
echo ""
echo "Services running:"
$DOCKER_COMPOSE ps
echo ""
echo -e "${GREEN}Happy testing!${NC}"
