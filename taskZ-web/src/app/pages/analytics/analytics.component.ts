import { CommonModule, isPlatformBrowser } from '@angular/common';
import { Component, Inject, OnInit, PLATFORM_ID } from '@angular/core';
import { FormsModule } from '@angular/forms';
import {
  AnalyticsQuery,
  AnalyticsOverview,
  AnalyticsService,
  RecommendationCandidate,
  RecommendationRequest,
  UserAnalytics,
  UserCategoryPerformance
} from '../../core/services/analytics.service';
import { Workspace, WorkspaceService } from '../../core/services/workspace.service';
import { Board, BoardService } from '../../core/services/board.service';

interface UserCategoryMatrixCell {
  category: string;
  completedTasks: number;
  onTimeRate: number;
  averageCompletionHours: number;
  score: number;
}

interface UserCategoryMatrixRow {
  userId: string;
  username: string;
  totalCompletedTasks: number;
  weightedAverageScore: number;
  categories: UserCategoryMatrixCell[];
}

@Component({
  selector: 'app-analytics',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './analytics.component.html',
  styleUrl: './analytics.component.scss'
})
export class AnalyticsComponent implements OnInit {
  private readonly isBrowser: boolean;
  readonly categoryOptions: { value: string; label: string }[] = [
    { value: '', label: 'Tüm kategoriler' },
    { value: 'frontend', label: 'Frontend' },
    { value: 'backend', label: 'Backend' },
    { value: 'ui_bug', label: 'UI Bug' },
    { value: 'api_bug', label: 'API Bug' },
    { value: 'mobile', label: 'Mobile' },
    { value: 'qa_test', label: 'QA/Test' },
    { value: 'infra_devops', label: 'Infra/DevOps' },
    { value: 'data', label: 'Data' },
    { value: 'other', label: 'Other' }
  ];
  readonly recommendationCategoryOptions = this.categoryOptions.filter((option) => option.value.length > 0);
  private readonly categoryLabelMap = new Map<string, string>(
    this.categoryOptions
      .filter((option) => option.value.length > 0)
      .map((option) => [option.value, option.label])
  );

  workspaces: Workspace[] = [];
  boards: Board[] = [];

  selectedWorkspaceId: number | null = null;
  selectedBoardId: number | null = null;
  selectedCategory = '';
  fromDate = '';
  toDate = '';

  loading = false;
  error = '';

  overview: AnalyticsOverview | null = null;
  userAnalytics: UserAnalytics[] = [];
  userCategoryPerformance: UserCategoryPerformance[] = [];
  userCategoryMatrix: UserCategoryMatrixRow[] = [];

  recommendationLoading = false;
  recommendationError = '';
  recommendation: RecommendationCandidate[] = [];
  recommendationTaskCategory = '';
  recommendationTaskCategoryConfidence = 0;
  recommendationInput: RecommendationRequest = {
    boardId: 0,
    title: '',
    description: '',
    priority: 'medium',
    topN: 3,
    workCategory: ''
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

  onCategoryChange(): void {
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
    let pendingRequestCount = 3;
    const completeRequest = (): void => {
      pendingRequestCount -= 1;
      if (pendingRequestCount <= 0) {
        this.loading = false;
      }
    };

    this.analyticsService.getOverview(query).subscribe({
      next: (overview) => {
        this.overview = overview;
        completeRequest();
      },
      error: (err) => {
        console.error('Error loading overview:', err);
        this.error = 'Analytics overview yüklenemedi.';
        completeRequest();
      }
    });

    this.analyticsService.getUserAnalytics(query).subscribe({
      next: (users) => {
        this.userAnalytics = users;
        completeRequest();
      },
      error: (err) => {
        console.error('Error loading user analytics:', err);
        this.error = 'Kullanıcı analytics verisi yüklenemedi.';
        completeRequest();
      }
    });

    this.analyticsService.getUserCategoryPerformance(query).subscribe({
      next: (rows) => {
        this.userCategoryPerformance = rows;
        this.userCategoryMatrix = this.buildUserCategoryMatrix(rows);
        completeRequest();
      },
      error: (err) => {
        console.error('Error loading user category performance:', err);
        this.error = 'Kategori bazlı kullanıcı performansı yüklenemedi.';
        this.userCategoryPerformance = [];
        this.userCategoryMatrix = [];
        completeRequest();
      }
    });
  }

  generateRecommendation(): void {
    this.recommendationError = '';
    this.recommendation = [];
    this.recommendationTaskCategory = '';
    this.recommendationTaskCategoryConfidence = 0;

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

    if (this.recommendationInput.workCategory?.trim()) {
      payload.workCategory = this.recommendationInput.workCategory.trim();
    }

    this.recommendationLoading = true;
    this.analyticsService.recommendAssignee(payload).subscribe({
      next: (res) => {
        this.recommendation = res.candidates ?? [];
        this.recommendationTaskCategory = res.taskCategory ?? '';
        this.recommendationTaskCategoryConfidence = res.taskCategoryConfidence ?? 0;
        this.recommendationLoading = false;
      },
      error: (err) => {
        console.error('Error generating recommendation:', err);
        this.recommendationError = 'Öneri alınamadı.';
        this.recommendationLoading = false;
      }
    });
  }

  private buildQuery(): AnalyticsQuery {
    const query: AnalyticsQuery = {};

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

    if (this.selectedCategory) {
      query.category = this.selectedCategory;
    }

    return query;
  }

  private buildUserCategoryMatrix(rows: UserCategoryPerformance[]): UserCategoryMatrixRow[] {
    const groupedByUser = new Map<string, UserCategoryMatrixRow>();

    for (const row of rows) {
      const existing = groupedByUser.get(row.userId);
      const normalizedCell: UserCategoryMatrixCell = {
        category: row.category,
        completedTasks: row.completedTasks,
        onTimeRate: row.onTimeRate,
        averageCompletionHours: row.averageCompletionHours,
        score: row.score
      };

      if (!existing) {
        groupedByUser.set(row.userId, {
          userId: row.userId,
          username: row.username,
          totalCompletedTasks: row.completedTasks,
          weightedAverageScore: row.score,
          categories: [normalizedCell]
        });
        continue;
      }

      existing.totalCompletedTasks += row.completedTasks;
      existing.categories.push(normalizedCell);
    }

    const matrix = Array.from(groupedByUser.values()).map((userRow) => {
      const weightedScoreSum = userRow.categories.reduce(
        (acc, categoryCell) => acc + (categoryCell.score * Math.max(1, categoryCell.completedTasks)),
        0
      );
      const weightedTaskCount = userRow.categories.reduce(
        (acc, categoryCell) => acc + Math.max(1, categoryCell.completedTasks),
        0
      );

      return {
        ...userRow,
        weightedAverageScore: weightedTaskCount > 0
          ? Number((weightedScoreSum / weightedTaskCount).toFixed(2))
          : 0,
        categories: [...userRow.categories].sort((a, b) => b.score - a.score)
      };
    });

    return matrix.sort((a, b) => b.weightedAverageScore - a.weightedAverageScore);
  }

  getCategoryLabel(category: string): string {
    return this.categoryLabelMap.get(category) ?? category;
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
