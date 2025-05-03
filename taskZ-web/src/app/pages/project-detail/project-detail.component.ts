import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute } from '@angular/router';
import { Board, BoardService, BoardUser } from '../../core/services/board.service';
import { CreateTaskDto, Task, TaskService } from '../../core/services/task.service';

@Component({
  selector: 'app-project-detail',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './project-detail.component.html',
  styleUrls: ['./project-detail.component.scss']
})
export class ProjectDetailComponent {

  constructor(
    private boardService: BoardService,
    private route: ActivatedRoute,
    private taskService: TaskService
  ) {}

  public board: Board | undefined;
  public boardUsers: BoardUser[] = [];
  public tasks: Task[] = [];

  selectedBoardId: number | null = null;

  isModalOpen = false;

  newTaskTitle = '';
  newTaskDescription = '';
  newTaskPriority: 'low' | 'medium' | 'high' = 'low';
  newTaskDueDate = '';
  newTaskUsername = '';
  newTaskStatusId: number | null = null;

  ngOnInit(): void {
    const boardId = Number(this.route.snapshot.paramMap.get('id'));
    this.selectedBoardId = boardId;

    if (boardId) {
      this.boardService.getBoard(boardId).subscribe(data => {
        this.board = data;
      });

      this.boardService.getBoardUsers(boardId).subscribe(data => {
        this.boardUsers = data;
      });

      this.taskService.getBoardTasks(boardId).subscribe(data => {
        this.tasks = data;
      });
    }
  }

  openTaskModal() {
    this.isModalOpen = true;
    this.resetForm();
  }

  closeTaskModal() {
    this.isModalOpen = false;
  }

  resetForm() {
    this.newTaskTitle = '';
    this.newTaskDescription = '';
    this.newTaskPriority = 'low';
    this.newTaskDueDate = '';
    this.newTaskUsername = '';
    this.newTaskStatusId = null;
  }

  createTask() {
    if (this.selectedBoardId === null) return;

    const isoDueDate = this.newTaskDueDate
      ? new Date(this.newTaskDueDate).toISOString()
      : undefined;

    const task: CreateTaskDto = {
      title: this.newTaskTitle,
      description: this.newTaskDescription,
      priority: this.newTaskPriority,
      dueDate: isoDueDate,
      username: this.newTaskUsername,
      statusId: this.newTaskStatusId ?? undefined
    };

    this.taskService.createTask(this.selectedBoardId, task).subscribe({
      next: (newTask) => {
        this.tasks.push(newTask);
        this.closeTaskModal();
        this.resetForm();
      },
      error: (error) => {
        console.error('Görev oluşturulurken bir hata oluştu:', error);
      }
    });
  }
}
