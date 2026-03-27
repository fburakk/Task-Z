import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { AuthService } from './auth.service';

export interface Task {
    id: number;
  boardId: number;
  statusId: number;
  title: string;
  description: string;
    priority: 'low' | 'medium' | 'high';
  dueDate: string; // ISO 8601
  assigneeId: string;
  assigneeUsername: string;
  position: number;
  createdBy: string;
  createdByUsername: string;
  created: string;
  lastModifiedBy: string;
  lastModifiedByUsername: string;
  lastModified: string;
}

export interface CreateTaskDto {
  title: string;
  description: string;
  priority: 'low' | 'medium' | 'high';
  dueDate?: string;
    username?: string;
    statusId?: number;
}

export interface UpdateTaskDto {
    title?: string;
    description?: string;
    priority?: 'low' | 'medium' | 'high';
    dueDate?: string;
    username?: string;
    statusId?: number;
    position?: number;
}

export interface AiSuggestedCandidate {
  userId: string;
  username: string;
  firstName?: string;
  lastName?: string;
  role: string;
  score: number;
  category: string;
  categoryScore: number;
  categoryCompletedTasks: number;
  activeTasks: number;
  overdueTasks: number;
}

export interface AiSuggestAssigneeResponse {
  recommendedUserId?: string;
  recommendedUsername?: string;
  taskCategory: string;
  taskCategoryConfidence: number;
  generatedAt: string;
  candidates: AiSuggestedCandidate[];
}

@Injectable({
  providedIn: 'root'
})
export class TaskService {
  private readonly baseUrl = 'http://localhost:5001/api/Task';

    constructor(private http: HttpClient, private authService: AuthService) {}

  // Get tasks by board
  getBoardTasks(boardId: number): Observable<Task[]> {
    return this.http.get<Task[]>(`${this.baseUrl}/board/${boardId}`, this.authService.getAuthHeaders());
  }

  // Get tasks by status
  getStatusTasks(statusId: number): Observable<Task[]> {
    return this.http.get<Task[]>(`${this.baseUrl}/status/${statusId}`, this.authService.getAuthHeaders());
  }

  // Create task
  createTask(boardId: number, task: CreateTaskDto): Observable<Task> {
    return this.http.post<Task>(`${this.baseUrl}/board/${boardId}`, task, this.authService.getAuthHeaders());
  }

  // Update task
  updateTask(id: number, task: UpdateTaskDto): Observable<Task> {
    return this.http.put<Task>(`${this.baseUrl}/${id}`, task, this.authService.getAuthHeaders());
  }

  // Delete task
  deleteTask(id: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/${id}`, this.authService.getAuthHeaders());
  }

    // Get assigned tasks
  getAssignedTasks(): Observable<Task[]> {
      return this.http.get<Task[]>(`${this.baseUrl}/assigned`, this.authService.getAuthHeaders());
  }

    // Move task to different status
    moveTask(taskId: number, newStatusId: number, position?: number): Observable<Task> {
        return this.updateTask(taskId, {
            statusId: newStatusId,
            position: position
        });
    }

    // Reorder task within status
    reorderTask(taskId: number, newPosition: number): Observable<Task> {
        return this.updateTask(taskId, {
            position: newPosition
        });
    }

    // Update task assignee
    assignTask(taskId: number, username: string): Observable<Task> {
        return this.updateTask(taskId, {
            username: username
        });
    }

    // AI suggest assignee (fast score-based recommendation)
    suggestAssignee(boardId: number, title: string, description: string, workCategory?: string): Observable<AiSuggestAssigneeResponse> {
        return this.http.post<AiSuggestAssigneeResponse>(
            'http://localhost:5001/api/ai/suggest-assignee',
            { boardId, title, description, workCategory: workCategory || null },
            this.authService.getAuthHeaders()
        );
    }

    // Get AI assistant context for task
    getTaskAssistantContext(taskId: number): Observable<any> {
        return this.http.post<any>(
            'http://localhost:5001/api/ai/assigned-task-assistant-context',
            { taskId },
            this.authService.getAuthHeaders()
        );
    }

}
