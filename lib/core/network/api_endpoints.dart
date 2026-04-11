class ApiEndpoints {
  // IMPORTANT: For Android emulator connecting to local backend, use 10.0.2.2.
  // For iOS simulator, use 127.0.0.1. For production, replace with your live URL.
  static const String baseUrl = 'http://10.0.2.2:3000/api/v1';

  // --- Public / Applicant Endpoints ---
  static const String submitApplication = '/applicants';
  static const String getRegions = '/regions';
  static String searchMembers(String term) => '/admins/members?search=$term';

  // --- Edit Application Endpoints ---
  static String getApplicantById(String id) => '/applicants/$id';
  static String resubmitApplication(String id) => '/applicants/$id';

  // --- Approval Endpoints ---
  static String verifyApprovalToken(String token, String role) => '/approvals/verify/$token?role=$role';
  static String submitApproval(String role) => '/approvals/${role.toLowerCase()}'; // e.g., /approvals/member

  // --- Payment Endpoints ---
  static String getPaymentStatus(String id) => '/payments/status/$id';
  static const String getFee = '/payments/fee';
  static const String createOrder = '/payments/create-order';
  static const String verifyPayment = '/payments/verify';

  // --- Admin Auth Endpoints ---
  static const String adminLogin = '/admins/login';

  // --- Admin Dashboard Endpoints ---
  static const String getAllApplicants = '/applicants';
  static const String getAllMembers = '/admins/all-members';

  static String reviewApplicant(String id) => '/admins/applicants/$id/review';
  static const String promoteApplicant = '/admins/promote';
  static String toggleMemberStatus(String id) => '/admins/members/$id/status';
  static String downloadIdCard(String id) => '/admins/members/$id/id-card';

  // Admin Auth & Profile
  static const String forgotPassword = '/admins/forgot-password';
  static const String resetPassword = '/admins/reset-password';
  static const String changePassword = '/admins/change-password';

  static const String updateFee = '/admins/settings/update-fee';
  static String adminEditApplicant(String id) => '/admins/applicants/$id/edit';
}