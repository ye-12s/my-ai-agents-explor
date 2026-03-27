# Example: Parallel Component Generation

A simpler example showing parallel task decomposition for frontend component development.

## Scenario

Build a user dashboard with 4 independent widgets:
1. User Profile Card
2. Activity Timeline
3. Statistics Charts
4. Notification List

## Decomposition

```
Dashboard Page
├── Widget A: User Profile    (independent)
├── Widget B: Activity Feed   (independent)
├── Widget C: Statistics      (independent)
├── Widget D: Notifications   (independent)
└── Integration: Dashboard    (depends on A, B, C, D)
```

All widgets are independent - no shared state, just composed together.

## Implementation

```typescript
// ============================================================
// PARALLEL COMPONENT GENERATION
// ============================================================

interface ComponentSpec {
  id: string;
  name: string;
  props: string[];
  dataRequirements: string[];
}

const components: ComponentSpec[] = [
  {
    id: 'user-profile',
    name: 'UserProfileCard',
    props: ['user: User'],
    dataRequirements: ['user.name', 'user.email', 'user.avatar']
  },
  {
    id: 'activity-timeline',
    name: 'ActivityTimeline',
    props: ['activities: Activity[]'],
    dataRequirements: ['activity.timestamp', 'activity.type', 'activity.description']
  },
  {
    id: 'statistics',
    name: 'StatisticsPanel',
    props: ['stats: UserStats'],
    dataRequirements: ['stats.loginCount', 'stats.documentsCreated', 'stats.lastActive']
  },
  {
    id: 'notifications',
    name: 'NotificationList',
    props: ['notifications: Notification[]', 'onDismiss: (id) => void'],
    dataRequirements: ['notification.id', 'notification.message', 'notification.read']
  }
];

// ============================================================
// PHASE 1: Generate All Components in Parallel
// ============================================================

async function generateComponents() {
  const componentTasks = components.map(spec =>
    task({
      category: "visual-engineering",
      load_skills: ["frontend-ui-ux"],
      run_in_background: true,
      description: `Generate ${spec.name} component`,
      prompt: buildComponentPrompt(spec)
    })
  );
  
  // All 4 components generated in parallel
  const componentResults = await Promise.all(
    componentTasks.map(t => background_output(t))
  );
  
  return componentResults;
}

function buildComponentPrompt(spec: ComponentSpec): string {
  return `
    COMPONENT: ${spec.name}
    
    PROPS:
    ${spec.props.map(p => `  - ${p}`).join('\n')}
    
    DATA:
    ${spec.dataRequirements.map(d => `  - ${d}`).join('\n')}
    
    REQUIREMENTS:
    - TypeScript React component
    - Tailwind CSS for styling
    - Props interface defined
    - Storybook story included
    - Unit tests with React Testing Library
    
    DESIGN SYSTEM:
    - Use design tokens from src/theme/
    - Follow component patterns in src/components/
    - Ensure accessibility (ARIA labels, keyboard nav)
    
    OUTPUT FILES:
    - src/components/${spec.id}/${spec.name}.tsx
    - src/components/${spec.id}/${spec.name}.test.tsx
    - src/components/${spec.id}/${spec.name}.stories.tsx
    - src/components/${spec.id}/index.ts
    
    CONSTRAINTS:
    - No external API calls (receive data via props)
    - No dependencies on other components in this batch
    - Self-contained and reusable
  `;
}

// ============================================================
// PHASE 2: Integration (Compose Components)
// ============================================================

async function createDashboardPage(componentResults: any[]) {
  const dashboardTask = task({
    category: "visual-engineering",
    load_skills: ["frontend-ui-ux"],
    run_in_background: false,  // Sequential - depends on components
    description: "Create dashboard page",
    prompt: `
      Create the Dashboard page that composes all widgets.
      
      COMPONENTS AVAILABLE (read-only):
      ${components.map(c => `
        - ${c.name}: src/components/${c.id}/${c.name}.tsx
          Props: ${c.props.join(', ')}
      `).join('\n')}
      
      PAGE REQUIREMENTS:
      - Route: /dashboard
      - Layout: 2-column grid on desktop, stack on mobile
      - Left column: UserProfileCard, StatisticsPanel
      - Right column: ActivityTimeline, NotificationList
      - Responsive design
      - Loading states for async data
      
      OUTPUT:
      - src/pages/Dashboard.tsx
      - src/pages/Dashboard.test.tsx
      
      IMPLEMENTATION:
      import { UserProfileCard } from '../components/user-profile';
      import { ActivityTimeline } from '../components/activity-timeline';
      import { StatisticsPanel } from '../components/statistics';
      import { NotificationList } from '../components/notifications';
      
      export function Dashboard() {
        // Fetch data for all components
        const { user, activities, stats, notifications } = useDashboardData();
        
        return (
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <div className="space-y-6">
              <UserProfileCard user={user} />
              <StatisticsPanel stats={stats} />
            </div>
            <div className="space-y-6">
              <ActivityTimeline activities={activities} />
              <NotificationList 
                notifications={notifications}
                onDismiss={handleDismiss}
              />
            </div>
          </div>
        );
      }
    `
  });
  
  return dashboardTask;
}

// ============================================================
// COMPLETE WORKFLOW
// ============================================================

async function buildDashboard() {
  console.log('🚀 Building Dashboard (Parallel Decomposition)');
  
  // Phase 1: All components in parallel
  console.log('\n📦 Phase 1: Generating components in parallel...');
  const startTime = Date.now();
  
  const componentResults = await generateComponents();
  const phase1Duration = Date.now() - startTime;
  
  console.log(`   ✅ Generated ${components.length} components in ${phase1Duration}ms`);
  
  // Validate all components
  for (const result of componentResults) {
    if (!result.success) {
      throw new Error('Component generation failed');
    }
  }
  
  // Phase 2: Integration
  console.log('\n🔗 Phase 2: Creating dashboard page...');
  const dashboard = await createDashboardPage(componentResults);
  
  console.log('\n✅ Dashboard build complete!');
  console.log(`   Total time: ${Date.now() - startTime}ms`);
  console.log(`   Parallel speedup: ~${components.length}x`);
  
  return dashboard;
}

// Execute
// buildDashboard();
```

## Alternative: Even More Parallel

If components share common patterns, extract them first:

```typescript
// Phase 0: Shared patterns (run once)
const sharedPatternsTask = task({
  prompt: `
    Create shared hooks and utilities for dashboard components:
    - useDashboardData() - data fetching hook
    - useDismissible() - notification dismissal hook
    - formatDate() - date formatting utility
    - Card wrapper component
    
    These will be used by all components.
  `
});

// Then Phase 1: All components (using shared patterns)
// Components can now reference these shared utilities
```

## Result

### Generated File Structure

```
src/
├── components/
│   ├── user-profile/
│   │   ├── UserProfileCard.tsx
│   │   ├── UserProfileCard.test.tsx
│   │   ├── UserProfileCard.stories.tsx
│   │   └── index.ts
│   ├── activity-timeline/
│   │   ├── ActivityTimeline.tsx
│   │   ├── ActivityTimeline.test.tsx
│   │   ├── ActivityTimeline.stories.tsx
│   │   └── index.ts
│   ├── statistics/
│   │   ├── StatisticsPanel.tsx
│   │   ├── StatisticsPanel.test.tsx
│   │   ├── StatisticsPanel.stories.tsx
│   │   └── index.ts
│   └── notifications/
│       ├── NotificationList.tsx
│       ├── NotificationList.test.tsx
│       ├── NotificationList.stories.tsx
│       └── index.ts
├── pages/
│   ├── Dashboard.tsx
│   └── Dashboard.test.tsx
└── hooks/
    └── useDashboardData.ts
```

### Time Comparison

| Approach | Time |
|----------|------|
| Sequential (4 components × 5 min) | ~20 minutes |
| Parallel (4 components simultaneously) | ~5 minutes |
| **Speedup** | **4x** |

## Key Insights

1. **Truly Independent** - No component depends on another's output
2. **Clear Contracts** - Props interfaces defined upfront
3. **Shared Patterns** - Common utilities extracted separately
4. **Composition** - Final assembly is lightweight

## When This Pattern Shines

- ✅ Multiple independent UI components
- ✅ Micro-frontend development
- ✅ API endpoint implementations
- ✅ Test file generation
- ✅ Documentation generation
- ✅ Any embarrassingly parallel work
