#!/bin/bash

echo "📝 WriteHabit Starting..."

cd "$(dirname "$0")"

# Start backend
cd backend
python3 app.py &
echo $! > ../.backend.pid
echo "✅ Backend started on http://localhost:5000"

cd ..

# Serve frontend
python3 -m http.server 8080 &
echo $! > .frontend.pid
echo "✅ Frontend started on http://localhost:8080/frontend/"

echo ""
echo "🌐 Access URLs:"
echo "   Frontend: http://localhost:8080/frontend/"
echo "   Backend:  http://localhost:5000"
echo ""
echo "Press Ctrl+C to stop"

trap 'kill $(cat .backend.pid) $(cat .frontend.pid) 2>/dev/null; rm -f .backend.pid .frontend.pid; exit' INT

wait
