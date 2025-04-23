import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { AuthService } from './auth.service';

export interface Workspace {
  id: number;
  name: string;
  userId: string;
  createdBy: string;
  created: string; 
}

@Injectable({
  providedIn: 'root'
})
export class WorkspaceService {
  private readonly apiUrl = 'http://localhost:5001/api/Workspace';

  constructor(private http: HttpClient,private authService: AuthService) {}

  // Create Workspace
  createWorkspace(name: string): Observable<Workspace> {
    console.log("createworkspace");
    return this.http.post<Workspace>(this.apiUrl, { name },this.authService.getAuthHeaders());
  }

  // Get all Workspaces
  getWorkspaces(): Observable<Workspace[]> {
    console.log("getworkspaces");
    return this.http.get<Workspace[]>(this.apiUrl,this.authService.getAuthHeaders());
  }

  // Get Workspace by ID
  getWorkspace(id: number): Observable<Workspace> {
    console.log("getworkspace");
    return this.http.get<Workspace>(`${this.apiUrl}/${id}`);
  }

  // Update Workspace
  updateWorkspace(id: number, name: string): Observable<void> {
    console.log("updateworkspace");
    return this.http.put<void>(`${this.apiUrl}/${id}`, { name });
  }

  // Delete Workspace
  deleteWorkspace(id: number): Observable<void> {
    console.log("workspace");
    return this.http.delete<void>(`${this.apiUrl}/${id}`);
  }
}
