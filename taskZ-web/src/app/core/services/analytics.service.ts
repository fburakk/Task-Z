import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { AuthService } from './auth.service';

export interface AnalyticsQuery {
  workspaceId?: number;
  boardId?: number;
  from?: string;
  to?: string;
  category?: string;
}

export interface AnalyticsOverview {
  totalTasks: number;
  completedTasks: number;
  activeTasks: number;
  overdueTasks: number;
  createdInRange: number;
  completedInRange: number;
  completionRate: number;
  averageCompletionHours: number;
  generatedAt: string;
}

export interface UserAnalytics {
  userId: string;
  username: string;
  assignedTasks: number;
  completedTasks: number;
  activeTasks: number;
  overdueTasks: number;
  completedInRange: number;
  completionRate: number;
  onTimeRate: number;
  averageCompletionHours: number;
}

export interface RecommendationRequest {
  boardId: number;
  title: string;
  description?: string;
  priority: 'low' | 'medium' | 'high';
  dueDate?: string;
  topN?: number;
  workCategory?: string;
}

export interface RecommendationSignals {
  activeTasks: number;
  overdueActiveTasks: number;
  completedTasks: number;
  onTimeRate: number;
  averageCompletionHours: number;
  expertiseScore: number;
  priorityMatchRate: number;
  category: string;
  categoryCompletedTasks: number;
  categoryAverageCompletionHours: number;
  categoryScore: number;
}

export interface RecommendationCandidate {
  userId: string;
  username: string;
  score: number;
  signals: RecommendationSignals;
  reasons: string[];
}

export interface RecommendationResponse {
  boardId: number;
  taskCategory: string;
  taskCategoryConfidence: number;
  generatedAt: string;
  candidates: RecommendationCandidate[];
}

export interface UserCategoryPerformance {
  userId: string;
  username: string;
  category: string;
  completedTasks: number;
  onTimeRate: number;
  averageCompletionHours: number;
  score: number;
  lastCompletedAt?: string | null;
}

export interface TaskCategoryAudit {
  taskId: number;
  taskTitle: string;
  boardId: number;
  boardName: string;
  category: string;
  categoryConfidence: number;
  assigneeId?: string | null;
  assigneeUsername?: string | null;
  createdAt: string;
}

@Injectable({
  providedIn: 'root'
})
export class AnalyticsService {
  private readonly baseUrl = 'http://localhost:5001/api/Analytics';

  constructor(private http: HttpClient, private authService: AuthService) {}

  getOverview(query: AnalyticsQuery): Observable<AnalyticsOverview> {
    return this.http.get<AnalyticsOverview>(`${this.baseUrl}/overview`, {
      ...this.authService.getAuthHeaders(),
      params: this.buildParams(query)
    });
  }

  getUserAnalytics(query: AnalyticsQuery): Observable<UserAnalytics[]> {
    return this.http.get<UserAnalytics[]>(`${this.baseUrl}/users`, {
      ...this.authService.getAuthHeaders(),
      params: this.buildParams(query)
    });
  }

  getUserCategoryPerformance(query: AnalyticsQuery): Observable<UserCategoryPerformance[]> {
    return this.http.get<UserCategoryPerformance[]>(`${this.baseUrl}/users/category-performance`, {
      ...this.authService.getAuthHeaders(),
      params: this.buildParams(query)
    });
  }

  getTaskCategoryAudit(query: AnalyticsQuery): Observable<TaskCategoryAudit[]> {
    return this.http.get<TaskCategoryAudit[]>(`${this.baseUrl}/tasks/category-audit`, {
      ...this.authService.getAuthHeaders(),
      params: this.buildParams(query)
    });
  }

  recommendAssignee(payload: RecommendationRequest): Observable<RecommendationResponse> {
    return this.http.post<RecommendationResponse>(
      `${this.baseUrl}/recommend-assignee`,
      payload,
      this.authService.getAuthHeaders()
    );
  }

  private buildParams(query: AnalyticsQuery): HttpParams {
    let params = new HttpParams();
    if (query.workspaceId) params = params.set('workspaceId', String(query.workspaceId));
    if (query.boardId) params = params.set('boardId', String(query.boardId));
    if (query.from) params = params.set('from', query.from);
    if (query.to) params = params.set('to', query.to);
    if (query.category) params = params.set('category', query.category);
    return params;
  }
}
