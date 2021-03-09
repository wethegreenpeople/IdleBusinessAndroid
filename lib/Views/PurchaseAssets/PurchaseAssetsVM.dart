import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:idlebusiness_mobile/Helpers/AppHelper.dart';
import 'package:idlebusiness_mobile/Stores/BusinessStore.dart';
import 'package:idlebusiness_mobile/Stores/PurchasableStore.dart';

class PurchaseAssetsVM extends ChangeNotifier {
  final Business business;
  final purchaseDebouncer = Debouncer(milliseconds: 750);

  int _purchaseAmount = 0; // Keep track of how many purchases we make in one go
  Timer _cashIncreaseTimer; // Timer to track our cash increase per second

  PurchaseAssetsVM(this.business);

  void purchaseAsset(Purchasable purchasable) {
    _purchaseAmount++;
    // "fake" stats updates. Update stats immediately for the user's enjoyment
    this.business.cash -= purchasable.calculateAdjustedCost();
    this.business.cashPerSecond += purchasable.cashPerSecondMod;
    this.business.maxItemAmount += purchasable.maxItemsMod;
    this.business.maxEmployeeAmount += purchasable.maxEmployeeMod;
    this.business.espionageChance += purchasable.espionageChanceMod;
    this.business.espionageDefense += purchasable.espionageDefenseMod;
    if (purchasable.purchasableTypeId == 1) this.business.amountEmployed++;
    if (purchasable.purchasableTypeId == 2) this.business.amountOwnedItems++;
    // Current adjusted cost
    purchasable.amountOwnedByBusiness +=
        1; // Increase amount owned after taking adjusted cost
    notifyListeners();

    purchaseDebouncer.run(() => PurchasableStore()
            .purchaseItem(this.business.id.toString(),
                purchasable.id.toString(), _purchaseAmount.toString())
            .then((value) {
          // Real stats updates. Update stats based on db
          purchasable.amountOwnedByBusiness =
              value.purchasable.amountOwnedByBusiness;
          purchasable = value.purchasable;
          this.business.cash = value.business.cash;
          this.business.cashPerSecond = value.business.cashPerSecond;
          this.business.amountEmployed = value.business.amountEmployed;
          this.business.maxEmployeeAmount = value.business.maxEmployeeAmount;
          this.business.espionageChance = value.business.espionageChance;
          this.business.espionageDefense = value.business.espionageDefense;
          this.business.lifeTimeEarnings = value.business.lifeTimeEarnings;
        }).whenComplete(() {
          _purchaseAmount = 0;
          notifyListeners();
        }));
  }

  void startCashIncreaseTimer() {
    if (_cashIncreaseTimer == null) {
      _cashIncreaseTimer = Timer.periodic(Duration(seconds: 1), (Timer t) {
        this.business.cash += this.business.cashPerSecond;
        this.business.lifeTimeEarnings += this.business.cashPerSecond;
        notifyListeners();
      });
    }
  }
}