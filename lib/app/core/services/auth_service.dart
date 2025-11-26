class AuthService {
  bool login(String user, String pass) {
    return user == 'admin' && pass == 'admin';
  }
}