import { Component, Inject, OnDestroy, OnInit, PLATFORM_ID } from '@angular/core';
import { Workspace, WorkspaceService } from '../../core/services/workspace.service';
import { Board, BoardService } from '../../core/services/board.service';
import { CommonModule, isPlatformBrowser } from '@angular/common';
import { RouterModule } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { Subscription } from 'rxjs';

@Component({
  selector: 'app-projects',
  imports: [CommonModule,RouterModule,FormsModule],
  templateUrl: './projects.component.html',
  styleUrl: './projects.component.scss'
})
export class ProjectsComponent implements OnInit, OnDestroy {

  workspaces: Workspace[] = [];
    boardsByWorkspace: { [key: number]: Board[] } = {};
    private readonly isBrowser: boolean;
    private workspaceCreatedSub?: Subscription;
  
    constructor(
      private workspaceService: WorkspaceService,
      private boardService: BoardService,
      @Inject(PLATFORM_ID) platformId: Object
    ) {
      this.isBrowser = isPlatformBrowser(platformId);
    }
  
    showBoardModal: boolean = false;
  newBoardName: string = '';
  selectedWorkspaceId: number | null = null;

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
  
  openBoardModal(workspaceId: number) {
    this.selectedWorkspaceId = workspaceId;
    this.newBoardName = '';
    this.showBoardModal = true;
  }
  
  closeBoardModal() {
    this.showBoardModal = false;
  }
  
  createNewBoard() {
    if (!this.newBoardName.trim() || this.selectedWorkspaceId === null) return;
  
    this.boardService.createBoard(this.selectedWorkspaceId, this.newBoardName, '#FFFFFF').subscribe({
      next: (newBoard) => {
        if (!this.boardsByWorkspace[this.selectedWorkspaceId!]) {
          this.boardsByWorkspace[this.selectedWorkspaceId!] = [];
        }
        this.boardsByWorkspace[this.selectedWorkspaceId!].push(newBoard);
        this.closeBoardModal();
      },
      error: (error) => {
        console.error('Error creating board:', error);
        const message = this.getErrorMessage(error);
        alert(`Proje oluşturulamadı: ${message}`);
      }
    });
  }

  deleteWorkspace(workspaceId: number): void {
    const confirmed = window.confirm('Bu workspace silinsin mi?');
    if (!confirmed) return;

    this.workspaceService.deleteWorkspace(workspaceId).subscribe({
      next: () => {
        this.workspaces = this.workspaces.filter((w) => w.id !== workspaceId);
        delete this.boardsByWorkspace[workspaceId];
      },
      error: (error) => {
        console.error('Workspace silinirken hata oluştu:', error);
      }
    });
  }

  deleteBoard(workspaceId: number, boardId: number, event: Event): void {
    event.preventDefault();
    event.stopPropagation();

    const confirmed = window.confirm('Bu proje silinsin mi?');
    if (!confirmed) return;

    this.boardService.deleteBoard(boardId).subscribe({
      next: () => {
        const boards = this.boardsByWorkspace[workspaceId] || [];
        this.boardsByWorkspace[workspaceId] = boards.filter((b) => b.id !== boardId);
      },
      error: (error) => {
        console.error('Proje silinirken hata oluştu:', error);
        const message = this.getErrorMessage(error);
        alert(`Proje silinemedi: ${message}`);
      }
    });
  }
  
    ngOnInit(): void {
      if (!this.isBrowser) {
        return;
      }

      this.workspaceCreatedSub = this.workspaceService.workspaceCreated$.subscribe((workspace) => {
        if (this.workspaces.some((w) => w.id === workspace.id)) {
          return;
        }

        this.workspaces = [...this.workspaces, workspace];
        this.boardsByWorkspace[workspace.id] = [];
      });

      this.workspaceService.getWorkspaces().subscribe((workspaces) => {
        this.workspaces = workspaces;
  
        this.workspaces.forEach((workspace) => {
          this.boardService.getBoards(workspace.id).subscribe((boards) => {
            this.boardsByWorkspace[workspace.id] = boards;
          });
        });
      });
    }

    ngOnDestroy(): void {
      this.workspaceCreatedSub?.unsubscribe();
    }
  

}
