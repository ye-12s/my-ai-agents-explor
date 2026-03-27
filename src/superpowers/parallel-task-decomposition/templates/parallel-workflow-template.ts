// ============================================================
// Parallel Task Decomposition - Implementation Template
// ============================================================
// Copy this template and adapt for your specific use case

interface SubTask {
  id: string;
  scope: string;
  description: string;
  inputs: string[];
  outputs: string[];
  dependencies: string[];
  validationCriteria: string[];
}

interface DecompositionPlan {
  tasks: SubTask[];
  phases: string[][];  // Task IDs grouped by execution phase
}

// ============================================================
// STEP 1: Define Your Decomposition Plan
// ============================================================

function createDecompositionPlan(): DecompositionPlan {
  const tasks: SubTask[] = [
    // Phase 1: Foundation (no dependencies)
    {
      id: 'module-a',
      scope: 'src/modules/A.ts',
      description: 'Implement core module A with business logic',
      inputs: ['API interface definition', 'Data models'],
      outputs: ['src/modules/A.ts', 'tests/A.test.ts'],
      dependencies: [],
      validationCriteria: [
        'All exported functions have tests',
        'No TypeScript errors',
        'Passes unit tests'
      ]
    },
    {
      id: 'module-b',
      scope: 'src/modules/B.ts',
      description: 'Implement core module B with business logic',
      inputs: ['API interface definition', 'Data models'],
      outputs: ['src/modules/B.ts', 'tests/B.test.ts'],
      dependencies: [],
      validationCriteria: [
        'All exported functions have tests',
        'No TypeScript errors',
        'Passes unit tests'
      ]
    },
    {
      id: 'utils',
      scope: 'src/utils/',
      description: 'Implement shared utilities',
      inputs: ['Utility requirements'],
      outputs: ['src/utils/helpers.ts', 'src/utils/validators.ts'],
      dependencies: [],
      validationCriteria: [
        'Functions are pure (no side effects)',
        '100% test coverage for utilities'
      ]
    },
    
    // Phase 2: Integration (depends on Phase 1)
    {
      id: 'integration',
      scope: 'src/integration.ts',
      description: 'Integrate modules A and B with utilities',
      inputs: [
        'src/modules/A.ts (read-only)',
        'src/modules/B.ts (read-only)',
        'src/utils/helpers.ts (read-only)'
      ],
      outputs: ['src/integration.ts', 'tests/integration.test.ts'],
      dependencies: ['module-a', 'module-b', 'utils'],
      validationCriteria: [
        'Integration tests pass',
        'No circular dependencies',
        'Proper error handling'
      ]
    },
    
    // Phase 3: API Layer (depends on Integration)
    {
      id: 'api',
      scope: 'src/api/',
      description: 'Implement REST API endpoints',
      inputs: ['src/integration.ts (read-only)'],
      outputs: ['src/api/routes.ts', 'src/api/controllers.ts'],
      dependencies: ['integration'],
      validationCriteria: [
        'All endpoints documented',
        'Input validation implemented',
        'Error responses follow API spec'
      ]
    }
  ];
  
  // Compute execution phases based on dependencies
  const phases = computePhases(tasks);
  
  return { tasks, phases };
}

// ============================================================
// STEP 2: Compute Execution Phases
// ============================================================

function computePhases(tasks: SubTask[]): string[][] {
  const completed = new Set<string>();
  const phases: string[][] = [];
  
  while (completed.size < tasks.length) {
    const phase: string[] = [];
    
    for (const task of tasks) {
      if (completed.has(task.id)) continue;
      
      // Task is ready if all dependencies are completed
      const depsSatisfied = task.dependencies.every(dep => completed.has(dep));
      
      if (depsSatisfied) {
        phase.push(task.id);
      }
    }
    
    if (phase.length === 0) {
      throw new Error('Circular dependency detected or orphaned task');
    }
    
    phases.push(phase);
    phase.forEach(id => completed.add(id));
  }
  
  return phases;
}

// ============================================================
// STEP 3: Build SubTask Prompts
// ============================================================

function buildSubTaskPrompt(subTask: SubTask, context: any): string {
  return `
    ============================================================
    SUBTASK: ${subTask.id}
    ============================================================
    
    SCOPE: ${subTask.scope}
    
    DESCRIPTION:
    ${subTask.description}
    
    INPUTS (provided):
    ${subTask.inputs.map(i => `  - ${i}`).join('\n')}
    
    ${context[subTask.id] ? `CONTEXT:\n${JSON.stringify(context[subTask.id], null, 2)}` : ''}
    
    OUTPUTS (you must produce):
    ${subTask.outputs.map(o => `  - ${o}`).join('\n')}
    
    CONSTRAINTS:
    - Only modify files within your scope: ${subTask.scope}
    - Do not modify files outside your scope
    - All outputs must be production-ready code
    - Follow existing codebase patterns and conventions
    
    VALIDATION CRITERIA (must all pass):
    ${subTask.validationCriteria.map(c => `  - [ ] ${c}`).join('\n')}
    
    BEFORE COMPLETING:
    1. Verify all outputs exist and are valid
    2. Run any available tests for your scope
    3. Check for TypeScript/lint errors
    4. Confirm validation criteria are met
    
    REPORT:
    - Success/failure status
    - List of files created/modified
    - Any issues encountered
    - Validation results
  `;
}

// ============================================================
// STEP 4: Execute Parallel Tasks
// ============================================================

async function executeParallelDecomposition(plan: DecompositionPlan) {
  const results = new Map<string, any>();
  const taskIdMap = new Map<string, string>(); // subTask.id -> taskId
  
  for (let phaseIndex = 0; phaseIndex < plan.phases.length; phaseIndex++) {
    const phase = plan.phases[phaseIndex];
    console.log(`\n🚀 Executing Phase ${phaseIndex + 1}/${plan.phases.length}: ${phase.join(', ')}`);
    
    // Dispatch all tasks in this phase in parallel
    const phasePromises = phase.map(async (taskId) => {
      const subTask = plan.tasks.find(t => t.id === taskId)!;
      
      console.log(`  Starting: ${taskId}`);
      
      // Collect results from dependencies as context
      const context: any = {};
      for (const depId of subTask.dependencies) {
        context[depId] = results.get(depId);
      }
      
      // Dispatch to subAgent
      const dispatchedTaskId = task(
        category="quick",
        load_skills=[], // Add relevant skills
        run_in_background=true,
        description=`${subTask.id}: ${subTask.description}`,
        prompt: buildSubTaskPrompt(subTask, context)
      );
      
      taskIdMap.set(taskId, dispatchedTaskId);
      
      return dispatchedTaskId;
    });
    
    const phaseTaskIds = await Promise.all(phasePromises);
    
    // Wait for all tasks in this phase to complete
    console.log(`  Waiting for Phase ${phaseIndex + 1} completion...`);
    
    for (const taskId of phase) {
      const dispatchedId = taskIdMap.get(taskId)!;
      const result = await background_output(task_id=dispatchedId);
      
      // Validate result
      const subTask = plan.tasks.find(t => t.id === taskId)!;
      const validation = validateSubTaskResult(result, subTask);
      
      if (!validation.valid) {
        throw new Error(`Task ${taskId} validation failed: ${validation.error}`);
      }
      
      results.set(taskId, result);
      console.log(`  ✅ Completed: ${taskId}`);
    }
  }
  
  return results;
}

// ============================================================
// STEP 5: Validation
// ============================================================

function validateSubTaskResult(result: any, subTask: SubTask): { valid: boolean; error?: string } {
  // Check success status
  if (!result.success) {
    return { valid: false, error: 'Task reported failure' };
  }
  
  // Check all expected outputs exist
  for (const output of subTask.outputs) {
    if (!result.files?.includes(output)) {
      return { valid: false, error: `Missing output: ${output}` };
    }
  }
  
  // Check validation criteria
  if (result.validationResults) {
    for (const criterion of subTask.validationCriteria) {
      if (!result.validationResults[criterion]) {
        return { valid: false, error: `Failed criterion: ${criterion}` };
      }
    }
  }
  
  return { valid: true };
}

// ============================================================
// STEP 6: Integration
// ============================================================

async function integrateResults(results: Map<string, any>, plan: DecompositionPlan) {
  console.log('\n📦 Integrating Results...');
  
  // Collect all files from all subtasks
  const allFiles: Map<string, string> = new Map();
  
  for (const [taskId, result] of results) {
    if (result.files) {
      for (const [path, content] of Object.entries(result.files)) {
        if (allFiles.has(path)) {
          throw new Error(`File conflict: ${path} produced by multiple tasks`);
        }
        allFiles.set(path, content as string);
      }
    }
  }
  
  // Write all files to workspace
  for (const [path, content] of allFiles) {
    console.log(`  Writing: ${path}`);
    // writeFile(path, content);
  }
  
  // Run final integration tests
  console.log('  Running integration tests...');
  // await runTests();
  
  return { files: allFiles };
}

// ============================================================
// MAIN EXECUTION
// ============================================================

async function main() {
  console.log('🎯 Parallel Task Decomposition');
  console.log('================================\n');
  
  // 1. Create decomposition plan
  const plan = createDecompositionPlan();
  console.log('📋 Decomposition Plan:');
  console.log(`   ${plan.tasks.length} tasks in ${plan.phases.length} phases`);
  plan.phases.forEach((phase, i) => {
    console.log(`   Phase ${i + 1}: ${phase.join(', ')}`);
  });
  
  // 2. Execute parallel decomposition
  const results = await executeParallelDecomposition(plan);
  
  // 3. Integrate results
  const finalOutput = await integrateResults(results, plan);
  
  console.log('\n✅ Parallel decomposition complete!');
  console.log(`   Total files produced: ${finalOutput.files.size}`);
  
  return finalOutput;
}

// Run if executed directly
// main().catch(console.error);
