import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute } from '@angular/router';
import { Board, BoardService, BoardUser, BoardStatus } from '../../core/services/board.service';
import { CreateTaskDto, Task, TaskService, UpdateTaskDto } from '../../core/services/task.service';
import { Inject, PLATFORM_ID } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';

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
  private readonly isBrowser: boolean;

  constructor(
    private boardService: BoardService,
    private route: ActivatedRoute,
    private taskService: TaskService,
    @Inject(PLATFORM_ID) platformId: Object
  ) {
    this.isBrowser = isPlatformBrowser(platformId);
  }

  public board: Board | undefined;
  public boardUsers: BoardUser[] = [];
  public tasks: Task[] = [];
  public tasksByStatus: TasksByStatus = {};
  public statuses: BoardStatus[] = [];

  selectedBoardId!: number; //////burda değişiklik yaptık sıkıntı çıkarsa bak

  isModalOpen = false;
  isStatusModalOpen = false;
  newStatusName = '';
  newStatusType: 'todo' | 'in_progress' | 'custom' | 'done' = 'custom';

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
  draggedStatusId: number | null = null;
  statusDragOverId: number | null = null;
  editingStatusId: number | null = null;
  editingStatusName = '';
  private statusDragPreviewEl: HTMLElement | null = null;


  showAddUserModal: boolean = false;
  newUsersName: string = '';

  private getErrorMessage(error: any): string {
    const payload = error?.error;
    if (typeof payload === 'string' && payload.trim()) {
      return payload;
    }

    if (payload?.message) {
      return String(payload.message);
    }

    if (payload?.title) {
      return String(payload.title);
    }

    if (payload?.errors && typeof payload.errors === 'object') {
      const firstKey = Object.keys(payload.errors)[0];
      const firstValue = firstKey ? payload.errors[firstKey] : null;
      if (Array.isArray(firstValue) && firstValue.length > 0) {
        return String(firstValue[0]);
      }
    }

    if (error?.message) {
      return String(error.message);
    }

    if (payload && typeof payload === 'object') {
      try {
        return JSON.stringify(payload);
      } catch {
        return 'Bilinmeyen hata';
      }
    }

    return 'Bilinmeyen hata';
  }

  ngOnInit(): void {
    if (!this.isBrowser) {
      return;
    }

    const boardId = Number(this.route.snapshot.paramMap.get('id'));
    this.selectedBoardId = boardId;

    if (boardId) {
      this.loadBoardData(boardId);
    }
  }

  addUserModal(){
    this.showAddUserModal = true;
    this.newUsersName = '';
  }

  closeAddUserModal(){
    this.showAddUserModal = false;
  }

  addNewUser(){
    if (!this.newUsersName.trim()) return;

    this.boardService.addUserToBoard(this.selectedBoardId, this.newUsersName, 'editor').subscribe(newUser => {
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
    this.newStatusType = 'custom';
  }

  closeStatusModal() {
    this.isStatusModalOpen = false;
  }

  createStatus() {
    if (!this.selectedBoardId || !this.newStatusName.trim()) return;

    if ((this.newStatusType === 'todo' || this.newStatusType === 'done') &&
      this.statuses.some((s) => s.type === this.newStatusType)) {
      alert(`Bu board içinde '${this.newStatusType}' tipi zaten var.`);
      return;
    }

    this.boardService.createBoardStatus(
      this.selectedBoardId,
      this.newStatusName.trim(),
      this.newStatusType
    ).subscribe({
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

  startRenameStatus(status: BoardStatus) {
    this.editingStatusId = status.id;
    this.editingStatusName = status.title;
  }

  cancelRenameStatus() {
    this.editingStatusId = null;
    this.editingStatusName = '';
  }

  saveRenameStatus(status: BoardStatus) {
    const nextName = this.editingStatusName?.trim();
    if (!nextName) {
      return;
    }

    if (nextName === status.title) {
      this.cancelRenameStatus();
      return;
    }

    this.boardService.updateBoardStatus(status.id, nextName).subscribe({
      next: (updatedStatus) => {
        status.title = updatedStatus.title;
        this.cancelRenameStatus();
      },
      error: (error) => {
        console.error('Error renaming status:', error);
        const message = this.getErrorMessage(error);
        alert(`Liste adı değiştirilemedi: ${message}`);
      }
    });
  }

  onStatusDragStart(status: BoardStatus, event: DragEvent) {
    this.draggedStatusId = status.id;
    this.statusDragOverId = null;
    if (event.dataTransfer) {
      event.dataTransfer.effectAllowed = 'move';
      event.dataTransfer.setData('text/plain', String(status.id));

      const headerEl = event.currentTarget as HTMLElement | null;
      const columnEl = headerEl?.closest('.status-column') as HTMLElement | null;

      if (columnEl && headerEl) {
        const preview = columnEl.cloneNode(true) as HTMLElement;
        preview.style.position = 'fixed';
        preview.style.top = '-10000px';
        preview.style.left = '-10000px';
        preview.style.width = `${columnEl.offsetWidth}px`;
        preview.style.pointerEvents = 'none';
        preview.style.opacity = '0.95';
        document.body.appendChild(preview);
        this.statusDragPreviewEl = preview;

        const headerRect = headerEl.getBoundingClientRect();
        const offsetX = Math.max(0, Math.min(headerRect.width, event.clientX - headerRect.left));
        const offsetY = Math.max(0, Math.min(headerRect.height, event.clientY - headerRect.top));

        event.dataTransfer.setDragImage(preview, offsetX || 24, offsetY || 24);
      }
    }
  }

  onStatusDragOver(event: DragEvent, targetStatusId: number) {
    if (this.draggedStatusId === null) {
      return;
    }

    event.preventDefault();
    if (event.dataTransfer) {
      event.dataTransfer.dropEffect = 'move';
    }

    if (this.draggedStatusId !== targetStatusId) {
      this.statusDragOverId = targetStatusId;
    }
  }

  onStatusDragEnd() {
    this.draggedStatusId = null;
    this.statusDragOverId = null;
    if (this.statusDragPreviewEl) {
      this.statusDragPreviewEl.remove();
      this.statusDragPreviewEl = null;
    }
  }

  onStatusDrop(event: DragEvent, targetStatusId: number) {
    if (this.draggedStatusId === null) {
      return;
    }

    event.preventDefault();
    event.stopPropagation();

    const sourceStatusId = this.draggedStatusId;
    this.statusDragOverId = null;

    if (sourceStatusId === targetStatusId) {
      this.draggedStatusId = null;
      return;
    }

    const fromIndex = this.statuses.findIndex((s) => s.id === sourceStatusId);
    const toIndex = this.statuses.findIndex((s) => s.id === targetStatusId);
    if (fromIndex === -1 || toIndex === -1) {
      this.draggedStatusId = null;
      return;
    }

    const previousStatuses = [...this.statuses];
    const reordered = [...this.statuses];
    const [movedStatus] = reordered.splice(fromIndex, 1);
    reordered.splice(toIndex, 0, movedStatus);
    reordered.forEach((status, index) => {
      status.position = index;
    });
    this.statuses = reordered;

    this.boardService.reorderBoardStatuses(
      this.selectedBoardId,
      this.statuses.map((s) => s.id)
    ).subscribe({
      next: () => {
        this.draggedStatusId = null;
      },
      error: (error) => {
        console.error('Error reordering statuses:', error);
        const message = this.getErrorMessage(error);
        alert(`Liste sırası kaydedilemedi: ${message}`);
        this.statuses = previousStatuses;
        this.draggedStatusId = null;
        this.loadStatuses();
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
    if (this.draggedStatusId !== null) {
      this.onStatusDrop(event, newStatusId);
      return;
    }

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
