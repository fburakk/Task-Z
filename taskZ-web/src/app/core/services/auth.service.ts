import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class AuthService {

  private baseUrl = 'http://localhost:5001/api';


  constructor(private http: HttpClient) {}

  register(userData: any): Observable<any> {
    return this.http.post(`${this.baseUrl}/Auth/register`, userData);
  }

  login(credentials: any): Observable<any> {
    return this.http.post(`${this.baseUrl}/Auth/login`, credentials);
  }

  refreshToken(token: string, refreshToken: string): Observable<any> {
    return this.http.post(`${this.baseUrl}/Account/refresh-token`, {
      token,
      refreshToken
    });
  }

  getProfile(): Observable<any> {
    const headers = this.getAuthHeaders();
    return this.http.get(`${this.baseUrl}/Account/profile`, { headers });
  }

  logout(): Observable<any> {
    const headers = this.getAuthHeaders();
    return this.http.post(`${this.baseUrl}/Account/logout`, {}, { headers });
  }

  deleteAccount(): Observable<any> {
    const headers = this.getAuthHeaders();
    return this.http.delete(`${this.baseUrl}/Account/delete-account`, { headers });
  }

  private getAuthHeaders(): HttpHeaders {
    const token = localStorage.getItem('jwtToken');
    return new HttpHeaders({
      Authorization: `Bearer ${token}`
    });
  }

  storeTokens(token: string, refreshToken: string): void {
    localStorage.setItem('jwtToken', token);
    localStorage.setItem('refreshToken', refreshToken);
  }

  getTokens(): { token: string | null, refreshToken: string | null } {
    return {
      token: localStorage.getItem('jwtToken'),
      refreshToken: localStorage.getItem('refreshToken')
    };
  }

  clearTokens(): void {
    localStorage.removeItem('jwtToken');
    localStorage.removeItem('refreshToken');
  }



}
