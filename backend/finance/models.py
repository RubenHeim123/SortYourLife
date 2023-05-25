import datetime
from django.conf import settings
from django.db import models
from django.contrib.auth.models import User

class AbstractTransaction(models.Model):
    id = models.BigAutoField(primary_key=True)
    category = models.CharField(max_length = 200)
    description = models.TextField(blank=True)
    account = models.CharField(max_length = 200)
    KIND_CHOICES = [
        ('Einnahme','Einnahme'),
        ('Ausgabe','Ausgabe')
    ]
    transactionkind = models.CharField(max_length = 200, choices=KIND_CHOICES)
    owner = models.ForeignKey(User, on_delete=models.CASCADE, null = True)

    class Meta:
        abstract = True
        
class Transaction(AbstractTransaction):
    date = models.DateField()
    amount = models.DecimalField(max_digits = 11, decimal_places = 2) 

    class Meta:
        ordering = ['-date']
        unique_together = ('category', 'description', 'account', 'date', 'amount', 'owner')
        
    def __str__(self):
        return self.date.strftime('%d.%m.%Y') + ' ' + self.category + ' ' + self.transactionkind

class FixedTransaction(AbstractTransaction):
    start_date = models.DateField()
    yearly_rate = models.DecimalField(max_digits = 11, decimal_places = 2)
    CHOICES = [
        ('täglich','täglich'),
        ('wöchentlich','wöchentlich'),
        ('monatlich','monatlich'), 
        ('vierteljährlich','vierteljährlich'), 
        ('halbjährlich','halbjährlich'), 
        ('jährlich','jährlich')
    ]
    pay_rythm = models.CharField(max_length=200, choices=CHOICES)

    class Meta:
        ordering = ['-start_date']
        unique_together = ('category', 'description', 'account', 'start_date', 'yearly_rate', 'pay_rythm', 'owner')

    def __str__(self):
        return self.start_date.strftime('%d.%m.%Y') + ' ' + self.category + ' ' + self.transactionkind


class Outgoingcategory(models.Model):
    outgoing_category_name = models.CharField(max_length=200)
    owner = models.ForeignKey(User, on_delete=models.CASCADE, null = True)
    budget = models.DecimalField(max_digits=11, decimal_places=2, default=0.00)

    class Meta:
        unique_together = ('outgoing_category_name', 'owner')

    def __str__(self):
        return self.outgoing_category_name

class Incomecategory(models.Model):
    income_category_name = models.CharField(max_length=200)
    owner = models.ForeignKey(User, on_delete=models.CASCADE, null = True)

    class Meta:
        unique_together = ('income_category_name', 'owner')

    def __str__(self):
        return self.income_category_name

class Account(models.Model):
    account_name = models.CharField(max_length=200)
    account_amount = models.DecimalField(max_digits = 11, decimal_places = 2, default=0.00)
    owner = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, default=1)

    class Meta:
        unique_together = ('account_name', 'owner')

    def __str__(self):
        return self.account_name