import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';
import { AuthService } from './auth.service';

export interface Board {
  id: number;
  workspaceId: number;
  name: string;
  background: string;
  isArchived: boolean;
}

export interface BoardStatus {
  id: number;
  title: string;
  position: number;
}

export interface BoardUser {
  id: number;
  userId: string;
  username: string;
  role: string;
}

@Injectable({
  providedIn: 'root'
})
export class BoardService {
  private apiUrl = 'http://localhost:5001/api/Board';

  constructor(private http: HttpClient,private authService: AuthService) {}

  // Create Board
  createBoard(workspaceId: number, name: string, background: string): Observable<Board> {
    const body = { workspaceId, name, background };
    return this.http.post<Board>(this.apiUrl, body, this.authService.getAuthHeaders());
  }

  // Get Boards by workspaceId
  getBoards(workspaceId: number): Observable<Board[]> {
    return this.http.get<Board[]>(`${this.apiUrl}?workspaceId=${workspaceId}`, this.authService.getAuthHeaders());
  }

  // Get Board by ID
  getBoard(id: number): Observable<Board> {
    return this.http.get<Board>(`${this.apiUrl}/${id}`, this.authService.getAuthHeaders());
  }

  // Update Board
  updateBoard(id: number, name: string, background: string): Observable<void> {
    const body = { name, background };
    return this.http.put<void>(`${this.apiUrl}/${id}`, body, this.authService.getAuthHeaders());
  }

  // Archive Board
  archiveBoard(id: number): Observable<void> {
    return this.http.put<void>(`${this.apiUrl}/${id}/archive`, {}, this.authService.getAuthHeaders());
  }

  // Get Board Statuses
  getBoardStatuses(id: number): Observable<BoardStatus[]> {
    return this.http.get<BoardStatus[]>(`${this.apiUrl}/${id}/statuses`, this.authService.getAuthHeaders());
  }

  // Get Board Users
  getBoardUsers(id: number): Observable<BoardUser[]> {
    return this.http.get<BoardUser[]>(`${this.apiUrl}/${id}/users`, this.authService.getAuthHeaders());
  }

  // Add User to Board
  addUserToBoard(id: number, username: string, role: string): Observable<BoardUser> {
    const body = { username, role };
    return this.http.post<BoardUser>(`${this.apiUrl}/${id}/users`, body, this.authService.getAuthHeaders());
  }

  // Create Board Status
  createBoardStatus(boardId: number, name: string): Observable<BoardStatus> {
    const body = { boardId, name };
    return this.http.post<BoardStatus>('http://localhost:5001/api/BoardStatus', body, this.authService.getAuthHeaders());
  }
}
