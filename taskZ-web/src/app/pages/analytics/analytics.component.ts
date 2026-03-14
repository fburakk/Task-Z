import { CommonModule, isPlatformBrowser } from '@angular/common';
import { Component, Inject, OnInit, PLATFORM_ID } from '@angular/core';
import { FormsModule } from '@angular/forms';
import {
  AnalyticsOverview,
  AnalyticsService,
  RecommendationCandidate,
  RecommendationRequest,
  UserAnalytics
} from '../../core/services/analytics.service';
import { Workspace, WorkspaceService } from '../../core/services/workspace.service';
import { Board, BoardService } from '../../core/services/board.service';

@Component({
  selector: 'app-analytics',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './analytics.component.html',
  styleUrl: './analytics.component.scss'
})
export class AnalyticsComponent implements OnInit {
  private readonly isBrowser: boolean;

  workspaces: Workspace[] = [];
  boards: Board[] = [];

  selectedWorkspaceId: number | null = null;
  selectedBoardId: number | null = null;
  fromDate = '';
  toDate = '';

  loading = false;
  error = '';

  overview: AnalyticsOverview | null = null;
  userAnalytics: UserAnalytics[] = [];

  recommendationLoading = false;
  recommendationError = '';
  recommendation: RecommendationCandidate[] = [];
  recommendationInput: RecommendationRequest = {
    boardId: 0,
    title: '',
    description: '',
    priority: 'medium',
    topN: 3
  };

  constructor(
    private workspaceService: WorkspaceService,
    private boardService: BoardService,
    private analyticsService: AnalyticsService,
    @Inject(PLATFORM_ID) platformId: Object
  ) {
    this.isBrowser = isPlatformBrowser(platformId);
  }

  ngOnInit(): void {
    if (!this.isBrowser) {
      return;
    }

    this.loadInitialData();
  }

  loadInitialData(): void {
    this.workspaceService.getWorkspaces().subscribe({
      next: (workspaces) => {
        this.workspaces = workspaces;
        if (workspaces.length > 0) {
          this.selectedWorkspaceId = workspaces[0].id;
          this.loadBoardsAndAnalytics();
          return;
        }

        this.loadAnalytics();
      },
      error: (err) => {
        console.error('Error loading workspaces:', err);
        this.error = 'Workspace bilgileri yüklenemedi.';
      }
    });
  }

  onWorkspaceChange(): void {
    this.selectedBoardId = null;
    this.boards = [];
    this.loadBoardsAndAnalytics();
  }

  onBoardChange(): void {
    this.recommendationInput.boardId = this.selectedBoardId ?? 0;
    this.loadAnalytics();
  }

  applyFilters(): void {
    this.loadAnalytics();
  }

  private loadBoardsAndAnalytics(): void {
    if (!this.selectedWorkspaceId) {
      this.loadAnalytics();
      return;
    }

    this.boardService.getBoards(this.selectedWorkspaceId).subscribe({
      next: (boards) => {
        this.boards = boards;
        if (boards.length > 0) {
          this.selectedBoardId = boards[0].id;
          this.recommendationInput.boardId = boards[0].id;
        } else {
          this.selectedBoardId = null;
          this.recommendationInput.boardId = 0;
        }
        this.loadAnalytics();
      },
      error: (err) => {
        console.error('Error loading boards:', err);
        this.error = 'Board bilgileri yüklenemedi.';
        this.loadAnalytics();
      }
    });
  }

  private loadAnalytics(): void {
    this.loading = true;
    this.error = '';

    const query = this.buildQuery();
    this.analyticsService.getOverview(query).subscribe({
      next: (overview) => {
        this.overview = overview;
      },
      error: (err) => {
        console.error('Error loading overview:', err);
        this.error = 'Analytics overview yüklenemedi.';
      }
    });

    this.analyticsService.getUserAnalytics(query).subscribe({
      next: (users) => {
        this.userAnalytics = users;
        this.loading = false;
      },
      error: (err) => {
        console.error('Error loading user analytics:', err);
        this.error = 'Kullanıcı analytics verisi yüklenemedi.';
        this.loading = false;
      }
    });
  }

  generateRecommendation(): void {
    this.recommendationError = '';
    this.recommendation = [];

    if (!this.selectedBoardId) {
      this.recommendationError = 'Önce bir board seçin.';
      return;
    }

    if (!this.recommendationInput.title.trim()) {
      this.recommendationError = 'Görev başlığı zorunlu.';
      return;
    }

    const payload: RecommendationRequest = {
      boardId: this.selectedBoardId,
      title: this.recommendationInput.title.trim(),
      description: this.recommendationInput.description?.trim() || '',
      priority: this.recommendationInput.priority,
      topN: this.recommendationInput.topN ?? 3
    };

    if (this.recommendationInput.dueDate) {
      const dueDate = new Date(this.recommendationInput.dueDate);
      payload.dueDate = dueDate.toISOString();
    }

    this.recommendationLoading = true;
    this.analyticsService.recommendAssignee(payload).subscribe({
      next: (res) => {
        this.recommendation = res.candidates ?? [];
        this.recommendationLoading = false;
      },
      error: (err) => {
        console.error('Error generating recommendation:', err);
        this.recommendationError = 'Öneri alınamadı.';
        this.recommendationLoading = false;
      }
    });
  }

  private buildQuery(): { workspaceId?: number; boardId?: number; from?: string; to?: string } {
    const query: { workspaceId?: number; boardId?: number; from?: string; to?: string } = {};

    if (this.selectedWorkspaceId) {
      query.workspaceId = this.selectedWorkspaceId;
    }

    if (this.selectedBoardId) {
      query.boardId = this.selectedBoardId;
    }

    if (this.fromDate) {
      query.from = new Date(this.fromDate).toISOString();
    }

    if (this.toDate) {
      const endOfDay = new Date(this.toDate);
      endOfDay.setHours(23, 59, 59, 999);
      query.to = endOfDay.toISOString();
    }

    return query;
  }

  formatDuration(hours: number | null | undefined): string {
    if (!hours || hours <= 0) {
      return '0 saniye';
    }

    const totalSeconds = Math.max(0, Math.round(hours * 3600));
    const hourPart = Math.floor(totalSeconds / 3600);
    const minutePart = Math.floor((totalSeconds % 3600) / 60);
    const secondPart = totalSeconds % 60;

    const parts: string[] = [];
    if (hourPart > 0) {
      parts.push(`${hourPart} saat`);
    }
    if (minutePart > 0 || hourPart > 0) {
      parts.push(`${minutePart} dk`);
    }
    parts.push(`${secondPart} saniye`);

    return parts.join(' ');
  }
}
