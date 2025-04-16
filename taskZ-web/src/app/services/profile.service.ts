import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

export interface UserProfile {
  id: string;
  userName: string;
  email: string;
  firstName: string;
  lastName: string;
  isVerified: boolean;
  roles: string[];
}

@Injectable({
  providedIn: 'root'
})
export class ProfileService {
  private apiUrl = 'http://localhost:5001/api';
  private httpOptions = {
    withCredentials: true,
    headers: {
      'Content-Type': 'application/json'
    }
  };

  constructor(private http: HttpClient) { }

  getProfile(): Observable<UserProfile> {
    return this.http.get<UserProfile>(`${this.apiUrl}/Account/profile`, this.httpOptions);
  }

  logout(): Observable<any> {
    return this.http.post(`${this.apiUrl}/Account/logout`, {}, this.httpOptions);
  }
} 