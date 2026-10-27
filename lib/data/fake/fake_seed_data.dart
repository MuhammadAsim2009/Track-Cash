import '../models/budget.dart';
import '../models/category.dart';
import '../models/transaction_entry.dart';
import '../models/transfer.dart';
import '../models/udhaar.dart';
import '../models/wallet.dart';

const String kDemoUserId = 'user_trackcash_demo';

// Wallet IDs
const String kWalletCashId = 'wallet_cash_01';
const String kWalletSavingsId = 'wallet_savings_02';
const String kWalletMobileId = 'wallet_mobile_03';

// Category IDs
const String kCatFoodId = 'cat_food';
const String kCatTransportId = 'cat_transport';
const String kCatBillsId = 'cat_bills';
const String kCatShoppingId = 'cat_shopping';
const String kCatEducationId = 'cat_education';
const String kCatHealthId = 'cat_health';
const String kCatEntertainmentId = 'cat_entertainment';
const String kCatExpenseOtherId = 'cat_expense_other';

const String kCatProjectEarningId = 'cat_project_earning';
const String kCatPocketMoneyId = 'cat_pocket_money';
const String kCatIncomeOtherId = 'cat_income_other';

/// Realistic initial seed data for Phase 1 UI demo.
class FakeSeedData {
  FakeSeedData._();

  static final DateTime _now = DateTime.now();

  static List<Wallet> get initialWallets => [
        Wallet(
          id: kWalletCashId,
          userId: kDemoUserId,
          name: 'Cash in hand',
          type: WalletType.cash,
          openingBalance: 0,
          createdAt: _now.subtract(const Duration(days: 30)),
          updatedAt: _now.subtract(const Duration(days: 30)),
        ),
        Wallet(
          id: kWalletSavingsId,
          userId: kDemoUserId,
          name: 'Savings',
          type: WalletType.savings,
          openingBalance: 0,
          countInDailyExpense: false,
          createdAt: _now.subtract(const Duration(days: 30)),
          updatedAt: _now.subtract(const Duration(days: 30)),
        ),
        Wallet(
          id: kWalletMobileId,
          userId: kDemoUserId,
          name: 'Easypaisa / JazzCash',
          type: WalletType.mobileWallet,
          openingBalance: 0,
          createdAt: _now.subtract(const Duration(days: 30)),
          updatedAt: _now.subtract(const Duration(days: 30)),
        ),
      ];

  static List<AppCategory> get initialCategories => [
        // Expense categories
        AppCategory(
          id: kCatFoodId,
          userId: kDemoUserId,
          name: 'Food',
          type: CategoryType.expense,
          icon: 'restaurant',
          color: 0xFFEF4444, // Red-500
          isDefault: true,
          createdAt: _now.subtract(const Duration(days: 30)),
          updatedAt: _now.subtract(const Duration(days: 30)),
        ),
        AppCategory(
          id: kCatTransportId,
          userId: kDemoUserId,
          name: 'Transport',
          type: CategoryType.expense,
          icon: 'directions_bus',
          color: 0xFFF97316, // Orange-500
          isDefault: true,
          createdAt: _now.subtract(const Duration(days: 30)),
          updatedAt: _now.subtract(const Duration(days: 30)),
        ),
        AppCategory(
          id: kCatBillsId,
          userId: kDemoUserId,
          name: 'Bills',
          type: CategoryType.expense,
          icon: 'receipt_long',
          color: 0xFFEAB308, // Yellow-500
          isDefault: true,
          createdAt: _now.subtract(const Duration(days: 30)),
          updatedAt: _now.subtract(const Duration(days: 30)),
        ),
        AppCategory(
          id: kCatShoppingId,
          userId: kDemoUserId,
          name: 'Shopping',
          type: CategoryType.expense,
          icon: 'shopping_bag',
          color: 0xFFEC4899, // Pink-500
          isDefault: true,
          createdAt: _now.subtract(const Duration(days: 30)),
          updatedAt: _now.subtract(const Duration(days: 30)),
        ),
        AppCategory(
          id: kCatEducationId,
          userId: kDemoUserId,
          name: 'Education',
          type: CategoryType.expense,
          icon: 'school',
          color: 0xFF8B5CF6, // Purple-500
          isDefault: true,
          createdAt: _now.subtract(const Duration(days: 30)),
          updatedAt: _now.subtract(const Duration(days: 30)),
        ),
        AppCategory(
          id: kCatHealthId,
          userId: kDemoUserId,
          name: 'Health',
          type: CategoryType.expense,
          icon: 'medical_services',
          color: 0xFF06B6D4, // Cyan-500
          isDefault: true,
          createdAt: _now.subtract(const Duration(days: 30)),
          updatedAt: _now.subtract(const Duration(days: 30)),
        ),
        AppCategory(
          id: kCatEntertainmentId,
          userId: kDemoUserId,
          name: 'Entertainment',
          type: CategoryType.expense,
          icon: 'movie',
          color: 0xFF3B82F6, // Blue-500
          isDefault: true,
          createdAt: _now.subtract(const Duration(days: 30)),
          updatedAt: _now.subtract(const Duration(days: 30)),
        ),
        AppCategory(
          id: kCatExpenseOtherId,
          userId: kDemoUserId,
          name: 'Other',
          type: CategoryType.expense,
          icon: 'more_horiz',
          color: 0xFF64748B, // Slate-500
          isDefault: true,
          createdAt: _now.subtract(const Duration(days: 30)),
          updatedAt: _now.subtract(const Duration(days: 30)),
        ),
        // Income categories
        AppCategory(
          id: kCatProjectEarningId,
          userId: kDemoUserId,
          name: 'Project Earning',
          type: CategoryType.income,
          icon: 'work',
          color: 0xFF10B981, // Emerald-500
          isDefault: true,
          createdAt: _now.subtract(const Duration(days: 30)),
          updatedAt: _now.subtract(const Duration(days: 30)),
        ),
        AppCategory(
          id: kCatPocketMoneyId,
          userId: kDemoUserId,
          name: 'Pocket Money',
          type: CategoryType.income,
          icon: 'account_balance_wallet',
          color: 0xFF14B8A6, // Teal-500
          isDefault: true,
          createdAt: _now.subtract(const Duration(days: 30)),
          updatedAt: _now.subtract(const Duration(days: 30)),
        ),
        AppCategory(
          id: kCatIncomeOtherId,
          userId: kDemoUserId,
          name: 'Other',
          type: CategoryType.income,
          icon: 'attach_money',
          color: 0xFF22C55E, // Green-500
          isDefault: true,
          createdAt: _now.subtract(const Duration(days: 30)),
          updatedAt: _now.subtract(const Duration(days: 30)),
        ),
      ];

  static List<TransactionEntry> get initialTransactions => const [];

  static List<Transfer> get initialTransfers => const [];

  static List<Budget> get initialBudgets => const [];

  static List<Udhaar> get initialUdhaar => const [];
}
