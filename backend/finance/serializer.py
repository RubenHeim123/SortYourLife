import datetime
from rest_framework import serializers, fields
from django.core.validators import DecimalValidator, MaxValueValidator
from .models import *

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = '__all__'

class AccountSerializer(serializers.ModelSerializer):
    id = serializers.ReadOnlyField()
    owner = serializers.HiddenField(default=serializers.CurrentUserDefault())
    class Meta:
        model = Account
        fields = [
            'id',
            'account_name',
            'account_amount',
            'owner',
        ]

class FixedTransactionSerializer(serializers.ModelSerializer):  
    description = models.CharField(max_length = 65533, blank=True) 
    id = serializers.ReadOnlyField()
    owner = serializers.HiddenField(default=serializers.CurrentUserDefault())
    class Meta:
        model = FixedTransaction
        fields = '__all__'

class TransactionSerializer(serializers.ModelSerializer):  
    description = models.CharField(max_length = 65533, blank=True) 
    id = serializers.ReadOnlyField()
    owner = serializers.HiddenField(default=serializers.CurrentUserDefault())
    class Meta:
        model = Transaction
        fields = [
            'id',
            'date',
            'amount',
            'category',
            'description',
            'account',
            'transactionkind',
            'owner',
        ]

class OutgoingCategorySerializer(serializers.ModelSerializer):
    id = serializers.ReadOnlyField()
    owner = serializers.HiddenField(default=serializers.CurrentUserDefault())
    class Meta:
        model = Outgoingcategory
        fields = [
            'id',
            'outgoing_category_name',
            'owner',
            'budget',
        ]

class IncomeCategorySerializer(serializers.ModelSerializer):
    id = serializers.ReadOnlyField()
    owner = serializers.HiddenField(default=serializers.CurrentUserDefault())
    class Meta:
        model = Incomecategory
        fields = [
            'id',
            'income_category_name',
            'owner',
        ]