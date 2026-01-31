# Task Management System Implementation

## Overview
This implementation adds a task management system for maintenance staff with the following rules:
- **Maximum 5 active tasks** per maintenance staff member
- **Mandatory deadline** for each assigned task
- **Automatic overdue detection** when tasks pass their deadline without being completed
- **Management-only task assignment** with validation

## Changes Made

### 1. Database Changes (add_deadline_to_issues.sql)

**Execute this SQL script in Supabase to:**
- Add `deadline` column to `issues` table
- Create function `is_issue_overdue()` to check if an issue is overdue
- Create view `staff_active_issues_count` to track workload per staff

```sql
-- Run this in Supabase SQL Editor
ALTER TABLE public.issues ADD COLUMN IF NOT EXISTS deadline TIMESTAMPTZ;
```

### 2. Type Definitions Updated (src/types/index.ts)

Added to Issue interface:
- `deadline?: string` - ISO datetime string for task deadline
- `isOverdue?: boolean` - Computed field indicating if task is past deadline

### 3. Hook Updates (src/hooks/useIssues.ts)

#### Fetching Issues:
- Now includes `deadline` field from database
- Automatically calculates `isOverdue` status:
  - True if: has deadline AND past deadline AND not resolved/cannot-resolve
  - False otherwise

#### Assigning Issues:
The `assignIssue` function now:

**Parameters:**
- `issueId`: string - The issue to assign
- `staffId`: string - The maintenance staff member ID
- `deadline`: string (REQUIRED) - Deadline for completion

**Validation:**
1. ✅ **Deadline Required**: Returns error if deadline not provided
2. ✅ **5-Task Limit**: Checks staff's active task count
   - Active = status NOT IN ('resolved', 'cannot-resolve')
   - If active count >= 5, returns error with current count
3. ✅ **Updates Database**: Sets assigned_to, status, and deadline
4. ✅ **Notifications**: Sends notifications to both staff (with deadline) and student

**Error Messages:**
- `"Deadline is required when assigning a task"`
- `"Cannot assign task. This staff member already has X active tasks (maximum is 5)..."`

### 4. How It Works

#### Task Assignment Flow:
1. Management selects an issue to assign
2. Management selects maintenance staff member
3. **Management MUST provide a deadline**
4. System checks if staff has < 5 active tasks
5. If valid:
   - Issue is assigned with deadline
   - Status changes to 'assigned'
   - Staff receives notification with deadline
   - Student receives notification that issue was assigned

#### Overdue Detection:
- Automatically calculated when issues are fetched
- An issue is overdue if:
  * It has a deadline set
  * Current time > deadline
  * Status is not 'resolved' or 'cannot-resolve'

#### Workload Management:
- Active tasks = All tasks except 'resolved' and 'cannot-resolve'
- Maximum 5 active tasks per staff member
- When staff completes a task (marks as resolved), their active count decreases
- Only then can management assign new tasks to them

## UI Updates Needed

### Issue Management Page (for Management)
You need to update the assignment modal/form to:

1. **Add deadline input field**:
```tsx
<Input
    type="datetime-local"
    label="Deadline *"
    value={deadline}
    onChange={(e) => setDeadline(e.target.value)}
    required
    min={new Date().toISOString().slice(0, 16)}
/>
```

2. **Update assignIssue call**:
```tsx
await assignIssue(issueId, selectedStaffId, deadline);
```

3. **Display staff workload**:
```tsx
// Show active task count next to each staff member
{staff.name} ({activeTaskCount}/5 tasks)
```

4. **Disable assignment** if staff has 5 active tasks

### Issue List Display
Add visual indicators for:
- **Deadline badge**: Show deadline date
- **Overdue badge**: Red badge if `issue.isOverdue === true`
- **Time remaining**: Calculate and show days/hours until deadline

Example:
```tsx
{issue.deadline && (
    <div className="flex gap-2">
        <Badge variant={issue.isOverdue ? "danger" : "info"}>
            {issue.isOverdue ? "OVERDUE" : "Due"}: {new Date(issue.deadline).toLocaleDateString()}
        </Badge>
    </div>
)}
```

## Testing Checklist

### Database Setup:
- [ ] Run `add_deadline_to_issues.sql` in Supabase
- [ ] Verify `deadline` column exists in `issues` table
- [ ] Verify view `staff_active_issues_count` was created

### Task Assignment:
- [ ] Try assigning without deadline → Should show error
- [ ] Assign task with deadline → Should work
- [ ] Try assigning 6th task to same staff → Should show error
- [ ] Complete a task (mark as resolved) → Active count should decrease
- [ ] Now can assign another task to that staff

### Overdue Detection:
- [ ] Set deadline in the past → Should show as overdue
- [ ] Set deadline in the future → Should not show as overdue
- [ ] Mark overdue task as resolved → Should no longer show as overdue

### Notifications:
- [ ] Staff receives notification with deadline date
- [ ] Student receives notification that issue was assigned

## Next Steps

1. **Run SQL Script**: Execute `add_deadline_to_issues.sql` in Supabase
2. **Update Management UI**: Add deadline input to assignment form
3. **Add Visual Indicators**: Show deadline and overdue status in issue lists
4. **Test Assignment**: Try assigning multiple tasks to verify 5-task limit
5. **Test Overdue**: Create tasks with past deadlines to verify overdue detection

## Benefits

✅ **Prevents Staff Overload**: Maximum 5 active tasks ensures manageable workload
✅ **Clear Deadlines**: Every task has a completion deadline
✅ **Automatic Tracking**: Overdue tasks are automatically detected
✅ **Better Planning**: Management can see staff workload before assigning
✅ **Fair Distribution**: System prevents assigning too many tasks to one person
