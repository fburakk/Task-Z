import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { TaskService, Task } from '../../core/services/task.service';
import { Inject, PLATFORM_ID } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';

@Component({
  selector: 'app-my-cards',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './my-cards.component.html',
  styleUrl: './my-cards.component.css'
})
export class MyCardsComponent implements OnInit {
  tasks: Task[] = [];
  loading: boolean = true;
  error: string | null = null;
  private readonly isBrowser: boolean;
  aiLoading: { [key: number]: boolean } = {};

  constructor(
    private taskService: TaskService,
    @Inject(PLATFORM_ID) platformId: Object
  ) {
    this.isBrowser = isPlatformBrowser(platformId);
  }

  ngOnInit() {
    if (!this.isBrowser) {
      this.loading = false;
      return;
    }

    this.loadAssignedTasks();
  }

  loadAssignedTasks() {
    this.loading = true;
    this.error = null;
    
    this.taskService.getAssignedTasks().subscribe({
      next: (tasks) => {
        this.tasks = tasks;
        this.loading = false;
      },
      error: (err) => {
        this.error = 'Failed to load tasks. Please try again later.';
        this.loading = false;
        console.error('Error loading tasks:', err);
      }
    });
  }

  getPriorityClass(priority: string): string {
    switch (priority.toLowerCase()) {
      case 'high': return 'priority-high';
      case 'medium': return 'priority-medium';
      case 'low': return 'priority-low';
      default: return '';
    }
  }

  formatDate(date: string): string {
    return new Date(date).toLocaleDateString();
  }

  getAIAssistantContext(taskId: number, taskTitle: string) {
    this.aiLoading[taskId] = true;
    this.taskService.getTaskAssistantContext(taskId).subscribe({
      next: (response) => {
        this.aiLoading[taskId] = false;
        const message = typeof response === 'string' ? response : JSON.stringify(response, null, 2);
        alert(message);
      },
      error: (err) => {
        this.aiLoading[taskId] = false;
        console.error('Error getting AI context:', err);
        alert('Failed to get AI assistant context. Please try again.');
      }
    });
  }
}
