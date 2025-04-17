import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Injectable, PLATFORM_ID, Inject } from '@angular/core';
import { Observable } from 'rxjs';
import { isPlatformBrowser } from '@angular/common';

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private baseUrl = 'http://localhost:5001/api';
  private isBrowser: boolean;

  constructor(
    private http: HttpClient,
    @Inject(PLATFORM_ID) platformId: Object
  ) {
    this.isBrowser = isPlatformBrowser(platformId);
  }

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

  logout(): Observable<any> {
    return this.http.post(`${this.baseUrl}/Account/logout`, {}, this.getAuthHeaders());
  }

  deleteAccount(): Observable<any> {
    return this.http.delete(`${this.baseUrl}/Account/delete-account`, this.getAuthHeaders());
  }

  private getAuthHeaders(): { headers: HttpHeaders } {
    if (!this.isBrowser) {
      return {
        headers: new HttpHeaders({
          'Content-Type': 'application/json'
        })
      };
    }

    const token = localStorage.getItem('jwtToken');
    return {
      headers: new HttpHeaders({
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      })
    };
  }

  storeTokens(token: string, refreshToken: string): void {
    if (!this.isBrowser) return;
    localStorage.setItem('jwtToken', token);
    localStorage.setItem('refreshToken', refreshToken);
  }

  getTokens(): { token: string | null, refreshToken: string | null } {
    if (!this.isBrowser) return { token: null, refreshToken: null };
    return {
      token: localStorage.getItem('jwtToken'),
      refreshToken: localStorage.getItem('refreshToken')
    };
  }

  clearTokens(): void {
    if (!this.isBrowser) return;
    localStorage.removeItem('jwtToken');
    localStorage.removeItem('refreshToken');
  }

  isLoggedIn(): boolean {
    if (!this.isBrowser) return false;
    return !!localStorage.getItem('jwtToken');
  }
}
