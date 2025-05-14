import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute } from '@angular/router';
import { Board, BoardService, BoardUser, BoardStatus } from '../../core/services/board.service';
import { CreateTaskDto, Task, TaskService, UpdateTaskDto } from '../../core/services/task.service';

interface TasksByStatus {
  [statusId: number]: Task[];
}

@Component({
  selector: 'app-project-detail',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './project-detail.component.html',
  styleUrls: ['./project-detail.component.scss']
})
export class ProjectDetailComponent implements OnInit {

  constructor(
    private boardService: BoardService,
    private route: ActivatedRoute,
    private taskService: TaskService
  ) {}

  public board: Board | undefined;
  public boardUsers: BoardUser[] = [];
  public tasks: Task[] = [];
  public tasksByStatus: TasksByStatus = {};
  public statuses: BoardStatus[] = [];

  selectedBoardId!: number; //////burda değişiklik yaptık sıkıntı çıkarsa bak

  isModalOpen = false;
  isStatusModalOpen = false;
  newStatusName = '';

  newTaskTitle = '';
  newTaskDescription = '';
  newTaskPriority: 'low' | 'medium' | 'high' = 'low';
  newTaskDueDate = '';
  newTaskUsername = '';
  private currentStatusId: number | null = null;

  isTaskDetailModalOpen = false;
  selectedTask: Task | null = null;

  // Task management
  draggedTask: Task | null = null;
  editingTask: Task | null = null;


  showAddUserModal: boolean = false;
  newUsersName: string = '';
  newUsersRole: 'editor' | 'viewer' = 'viewer';

  ngOnInit(): void {
    const boardId = Number(this.route.snapshot.paramMap.get('id'));
    this.selectedBoardId = boardId;

    if (boardId) {
      this.loadBoardData(boardId);
    }
  }

  addUserModal(){
    this.showAddUserModal = true;
    this.newUsersName = '';
    this.newUsersRole = 'viewer';
  }

  closeAddUserModal(){
    this.showAddUserModal = false;
  }

  addNewUser(){
    if (!this.newUsersName.trim() || !this.newUsersRole.trim() ) return;

    this.boardService.addUserToBoard(this.selectedBoardId,this.newUsersName,this.newUsersRole).subscribe(newUser => {
      console.log('Yeni kullanıcı eklendi:', newUser);
      this.closeAddUserModal();})
  }

  loadBoardData(boardId: number) {
    // Get board details
    this.boardService.getBoard(boardId).subscribe({
      next: (data) => {
        console.log('Board data:', data);
        this.board = data;
      },
      error: (error) => {
        console.error('Error fetching board:', error);
      }
    });

    // Get board users
    this.boardService.getBoardUsers(boardId).subscribe({
      next: (data) => {
        console.log('Board users:', data);
        this.boardUsers = data;
      },
      error: (error) => {
        console.error('Error fetching board users:', error);
      }
    });

    // Get board statuses and then load tasks
    this.loadStatuses();
  }

  loadStatuses() {
    if (!this.selectedBoardId) return;

    this.boardService.getBoardStatuses(this.selectedBoardId).subscribe({
      next: (data) => {
        console.log('Board statuses:', data);
        this.statuses = data;
        this.loadTasksForAllStatuses();
      },
      error: (error) => {
        console.error('Error fetching board statuses:', error);
      }
    });
  }

  loadTasksForAllStatuses() {
    this.tasksByStatus = {};
    this.statuses.forEach(status => {
      this.taskService.getStatusTasks(status.id).subscribe({
        next: (tasks) => {
          console.log(`Tasks for status ${status.id}:`, tasks);
          this.tasksByStatus[status.id] = tasks;
        },
        error: (error) => {
          console.error(`Error fetching tasks for status ${status.id}:`, error);
        }
      });
    });
  }

  openStatusModal() {
    this.isStatusModalOpen = true;
    this.newStatusName = '';
  }

  closeStatusModal() {
    this.isStatusModalOpen = false;
  }

  createStatus() {
    if (!this.selectedBoardId || !this.newStatusName.trim()) return;

    this.boardService.createBoardStatus(this.selectedBoardId, this.newStatusName.trim()).subscribe({
      next: (newStatus) => {
        console.log('New status created:', newStatus);
        this.loadStatuses(); // Reload all statuses
        this.closeStatusModal();
      },
      error: (error) => {
        console.error('Error creating status:', error);
      }
    });
  }

  openTaskModal(statusId: number) {
    this.currentStatusId = statusId;
    this.isModalOpen = true;
    this.resetForm();
  }

  closeTaskModal() {
    this.isModalOpen = false;
    this.currentStatusId = null;
  }

  resetForm() {
    this.newTaskTitle = '';
    this.newTaskDescription = '';
    this.newTaskPriority = 'low';
    this.newTaskDueDate = '';
    this.newTaskUsername = '';
  }

  createTask() {
    if (!this.selectedBoardId || !this.currentStatusId) {
      console.error('Missing board ID or status ID');
      return;
    }

    const isoDueDate = this.newTaskDueDate
      ? new Date(this.newTaskDueDate).toISOString()
      : undefined;

    const task: CreateTaskDto = {
      title: this.newTaskTitle,
      description: this.newTaskDescription,
      priority: this.newTaskPriority,
      dueDate: isoDueDate,
      username: this.newTaskUsername || undefined,
      statusId: this.currentStatusId
    };

    console.log('Creating task:', task);

    this.taskService.createTask(this.selectedBoardId, task).subscribe({
      next: (newTask) => {
        console.log('Task created:', newTask);
        if (newTask.statusId) {
          if (!this.tasksByStatus[newTask.statusId]) {
            this.tasksByStatus[newTask.statusId] = [];
          }
          this.tasksByStatus[newTask.statusId].push(newTask);
        }
        this.closeTaskModal();
      },
      error: (error) => {
        console.error('Error creating task:', error);
      }
    });
  }

  getPriorityClass(priority: string): string {
    switch (priority) {
      case 'high':
        return 'priority-high';
      case 'medium':
        return 'priority-medium';
      case 'low':
        return 'priority-low';
      default:
        return '';
    }
  }

  getStatusTitle(statusId: number | undefined): string {
    if (!statusId) return 'Unknown';
    const status = this.statuses.find(s => s.id === statusId);
    return status ? status.title : 'Unknown';
  }

  openTaskDetailModal(task: Task) {
    this.selectedTask = task;
    this.isTaskDetailModalOpen = true;
  }

  closeTaskDetailModal() {
    this.isTaskDetailModalOpen = false;
    this.selectedTask = null;
    this.editingTask = null;
  }

  formatDate(date: string | undefined): string {
    if (!date) return 'Not set';
    return new Date(date).toLocaleDateString();
  }

  // Task drag and drop
  onDragStart(task: Task) {
    this.draggedTask = task;
  }

  onDragOver(event: DragEvent, statusId: number) {
    event.preventDefault();
  }

  onDrop(event: DragEvent, newStatusId: number) {
    event.preventDefault();
    if (!this.draggedTask) return;

    const task = this.draggedTask;
    this.draggedTask = null;

    if (task.statusId === newStatusId) return;

    // Calculate new position (at the end of the new status)
    const tasksInNewStatus = this.tasksByStatus[newStatusId] || [];
    const newPosition = tasksInNewStatus.length;

    this.taskService.moveTask(task.id, newStatusId, newPosition).subscribe({
      next: (updatedTask) => {
        // Remove task from old status
        if (this.tasksByStatus[task.statusId]) {
          this.tasksByStatus[task.statusId] = this.tasksByStatus[task.statusId].filter(t => t.id !== task.id);
        }
        // Add task to new status
        if (!this.tasksByStatus[newStatusId]) {
          this.tasksByStatus[newStatusId] = [];
        }
        this.tasksByStatus[newStatusId].push(updatedTask);
      },
      error: (error) => {
        console.error('Error moving task:', error);
      }
    });
  }

  // Task editing
  startEditingTask(task: Task) {
    this.editingTask = {
      id: task.id,
      boardId: task.boardId,
      statusId: task.statusId,
      title: task.title,
      description: task.description,
      priority: task.priority,
      dueDate: task.dueDate,
      assigneeId: task.assigneeId,
      assigneeUsername: task.assigneeUsername,
      position: task.position,
      createdBy: task.createdBy,
      createdByUsername: task.createdByUsername,
      created: task.created,
      lastModifiedBy: task.lastModifiedBy,
      lastModifiedByUsername: task.lastModifiedByUsername,
      lastModified: task.lastModified
    };
    this.selectedTask = task;
    this.isTaskDetailModalOpen = true;
  }

  updateTask() {
    if (!this.editingTask) return;

    const updateDto: UpdateTaskDto = {
      title: this.editingTask.title,
      description: this.editingTask.description,
      priority: this.editingTask.priority,
      dueDate: this.editingTask.dueDate,
      username: this.editingTask.assigneeUsername
    };

    this.taskService.updateTask(this.editingTask.id, updateDto).subscribe({
      next: (updatedTask) => {
        // Update task in tasksByStatus
        if (this.tasksByStatus[updatedTask.statusId]) {
          const index = this.tasksByStatus[updatedTask.statusId].findIndex(t => t.id === updatedTask.id);
          if (index !== -1) {
            this.tasksByStatus[updatedTask.statusId][index] = updatedTask;
          }
        }
        this.closeTaskDetailModal();
      },
      error: (error) => {
        console.error('Error updating task:', error);
      }
    });
  }

  // Task deletion
  deleteTask(taskId: number, statusId: number) {
    if (confirm('Are you sure you want to delete this task?')) {
      this.taskService.deleteTask(taskId).subscribe({
        next: () => {
          if (this.tasksByStatus[statusId]) {
            this.tasksByStatus[statusId] = this.tasksByStatus[statusId].filter(t => t.id !== taskId);
          }
          this.closeTaskDetailModal();
        },
        error: (error) => {
          console.error('Error deleting task:', error);
        }
      });
    }
  }

  // Task assignment
  assignTask(taskId: number, username: string) {
    this.taskService.assignTask(taskId, username).subscribe({
      next: (updatedTask) => {
        if (this.tasksByStatus[updatedTask.statusId]) {
          const index = this.tasksByStatus[updatedTask.statusId].findIndex(t => t.id === updatedTask.id);
          if (index !== -1) {
            this.tasksByStatus[updatedTask.statusId][index] = updatedTask;
          }
        }
      },
      error: (error) => {
        console.error('Error assigning task:', error);
      }
    });
  }

  updateTaskPriority(taskId: number, priority: 'low' | 'medium' | 'high') {
    const updateDto: UpdateTaskDto = {
      priority: priority
    };

    this.taskService.updateTask(taskId, updateDto).subscribe({
      next: (updatedTask) => {
        // Update task in tasksByStatus
        if (this.tasksByStatus[updatedTask.statusId]) {
          const index = this.tasksByStatus[updatedTask.statusId].findIndex(t => t.id === updatedTask.id);
          if (index !== -1) {
            this.tasksByStatus[updatedTask.statusId][index] = updatedTask;
          }
        }
      },
      error: (error) => {
        console.error('Error updating task priority:', error);
      }
    });
  }
}
