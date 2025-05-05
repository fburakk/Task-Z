import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute } from '@angular/router';
import { Board, BoardService, BoardUser, BoardStatus } from '../../core/services/board.service';
import { CreateTaskDto, Task, TaskService } from '../../core/services/task.service';

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

  selectedBoardId: number | null = null;

  isModalOpen = false;
  isStatusModalOpen = false;
  newStatusName = '';

  newTaskTitle = '';
  newTaskDescription = '';
  newTaskPriority: 'low' | 'medium' | 'high' = 'low';
  newTaskDueDate = '';
  newTaskUsername = '';
  private currentStatusId: number | null = null;

  ngOnInit(): void {
    const boardId = Number(this.route.snapshot.paramMap.get('id'));
    this.selectedBoardId = boardId;

    if (boardId) {
      this.loadBoardData(boardId);
    }
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
}
