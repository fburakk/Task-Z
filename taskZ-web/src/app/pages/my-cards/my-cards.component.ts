import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { TaskService, Task } from '../../core/services/task.service';

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

  constructor(private taskService: TaskService) {}

  ngOnInit() {
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
} 