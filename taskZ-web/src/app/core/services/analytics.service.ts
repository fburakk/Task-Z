import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { AuthService } from './auth.service';

export interface AnalyticsQuery {
  workspaceId?: number;
  boardId?: number;
  from?: string;
  to?: string;
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
}

export interface RecommendationSignals {
  activeTasks: number;
  overdueActiveTasks: number;
  completedTasks: number;
  onTimeRate: number;
  averageCompletionHours: number;
  expertiseScore: number;
  priorityMatchRate: number;
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
  generatedAt: string;
  candidates: RecommendationCandidate[];
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
    return params;
  }
}
