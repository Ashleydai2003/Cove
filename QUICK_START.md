# 🚀 Quick Start Guide

## For iOS App Testing

### **Step 1: Start Backend Server (REQUIRED)**
```bash
# Navigate to Backend directory first!
cd Backend

# Then start the server
npm run dev
```

**⚠️ IMPORTANT**: You MUST be in the `Backend/` directory to run `npm run dev`

### **Step 2: Run iOS App**
- Open Xcode
- Select iOS Simulator 
- Run your app

### **Step 3: Stop Backend Server (When Done)**
```bash
# Stop the development server
pkill -f "ts-node src/local-server.ts"

# Or use Ctrl+C if running in foreground
```

### **Troubleshooting**
If you see "Could not connect to the server":
- ✅ Make sure you're in the `Backend/` directory
- ✅ Make sure `npm run dev` is running
- ✅ Check that server shows: `🚀 Local development server running on http://localhost:3001`

**Common Error**: Running `npm run dev` from root directory
```bash
# ❌ WRONG (from root directory)
npm run dev  # "Missing script: dev"

# ✅ CORRECT (from Backend directory)  
cd Backend
npm run dev
```

## For Database Development

### **Start Local Database**
```bash
cd Backend
npm run db:start
```

### **Create Migrations**
```bash
cd Backend
npm run prisma:migrate:dev
```

### **View Database**
```bash
cd Backend
npm run prisma:studio
```

## Full Documentation
- **Local Development**: `Backend/LOCAL_DEVELOPMENT.md`
- **Migration Workflow**: `Backend/MIGRATION_WORKFLOW.md`
- **API Testing**: `Backend/test-api.http` 