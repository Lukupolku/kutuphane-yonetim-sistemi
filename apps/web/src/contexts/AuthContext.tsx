import { createContext, useContext, useState, useCallback } from 'react';
import type { ReactNode } from 'react';

export type UserRole = 'ministry' | 'province' | 'district' | 'school';

export interface AuthUser {
  username: string;
  role: UserRole;
  province?: string;
  district?: string;
  schoolId?: string;
  schoolName?: string;
}

interface AuthContextType {
  user: AuthUser | null;
  login: (user: AuthUser) => void;
  logout: () => void;
}

const AuthContext = createContext<AuthContextType | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<AuthUser | null>(() => {
    const saved = sessionStorage.getItem('auth_user');
    return saved ? JSON.parse(saved) : null;
  });

  const login = useCallback((u: AuthUser) => {
    setUser(u);
    sessionStorage.setItem('auth_user', JSON.stringify(u));
  }, []);

  const logout = useCallback(() => {
    setUser(null);
    sessionStorage.removeItem('auth_user');
  }, []);

  return (
    <AuthContext.Provider value={{ user, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
}
