import datetime
from decimal import Decimal
import json
import logging
from django.shortcuts import render, HttpResponse
from django.http import Http404, HttpResponse
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from rest_framework.decorators import api_view, permission_classes
from rest_framework import viewsets
from rest_framework.authentication import SessionAuthentication, BasicAuthentication, TokenAuthentication
from rest_framework.permissions import IsAuthenticated
from rest_framework import status
from django.core import serializers
from .models import *
from .serializer import *
from datetime import date
from rest_framework.exceptions import ValidationError
from rest_framework.views import APIView
from django.db.models import Sum
from datetime import datetime, timedelta
from django.utils import timezone
from rest_framework import generics
from rest_framework.authtoken.models import Token
from django.contrib.auth.models import Group
import pandas as pd
from django.db.models import Sum, FloatField
from django.db.models.functions import Cast
import logging

class MyView(APIView):
    def post(self, request):
        transactions_df = pd.read_csv('RubenOutgoing.csv', sep=';')
        transactions_df['date'] = pd.to_datetime(transactions_df['date'], format='%d.%m.%Y')
        transactions_df['date'] = transactions_df['date'].dt.strftime('%Y-%m-%d')
        transactions_df['amount'] = transactions_df['amount'].str.replace(',', '.').astype(float)

        # Iterieren Sie durch jede Zeile des DataFrames und erstellen Sie ein neues Transaction-Objekt
        for index, row in transactions_df.iterrows():
            transaction = Transaction.objects.create(
                date=row['date'],
                amount=row['amount'],
                category=row['category'],
                description=row['description'],
                account=row['account'],
                transactionkind=row['transactionkind'],
                owner=request.user
            )
            transaction.save()

        # Geben Sie eine Erfolgsmeldung zurück
        return Response({'message': 'Transaktionen erfolgreich hinzugefügt'}, status=status.HTTP_201_CREATED)

@api_view(['GET'])
@permission_classes([AllowAny])
def checkBackendStatus(request):
    return Response(True)

@api_view(['POST'])
@permission_classes([AllowAny])
def checkToken(request):
    username = request.data.get('username')
    token = request.data.get('token')
    try:
        user = User.objects.get(username=username)
        if user.auth_token.key == token:
            return Response(True)
        else:
            return Response(False)
    except User.DoesNotExist:
        return Response(False)

@api_view(['POST'])
@permission_classes([AllowAny])
def register(request):
    serializer = UserSerializer(data=request.data, context={'request': request})
    if serializer.is_valid():
        user = serializer.save()
        group, created = Group.objects.get_or_create(name='Standard')
        # assign user to group
        user.groups.add(group)
        password = request.data.get('password')
        user.set_password(password)
        user.save()
        Token.objects.get_or_create(user=user)
        new_obj = User.objects.filter(username='admin').first()

        copy_acc = Account.objects.filter(owner=new_obj.id)
        for acc in copy_acc:
            Account.objects.get_or_create(
                account_name=acc.account_name,
                account_amount=0,
                owner=user,
            )

        copy_inc = Incomecategory.objects.filter(owner=new_obj.id)
        for inc in copy_inc:
            Incomecategory.objects.get_or_create(
                income_category_name=inc.income_category_name,
                owner=user,
            )

        copy_ogc = Outgoingcategory.objects.filter(owner=new_obj.id)
        for ogc in copy_ogc:
            Outgoingcategory.objects.get_or_create(
                outgoing_category_name=ogc.outgoing_category_name,
                budget=0,
                owner=user,
            )

        return Response(status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class UserList(generics.ListCreateAPIView):
    permission_classes = [IsAuthenticated]
    queryset = User.objects.all()
    serializer_class = UserSerializer

class UserDetail(generics.RetrieveUpdateDestroyAPIView):
    permission_classes = [IsAuthenticated]
    queryset = User.objects.all()
    serializer_class = UserSerializer

class cumulatedTransactions(APIView):
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]

    def income_transaction_list(self, request, kind):
        if kind == 'Einnahme':
            income_categories = Incomecategory.objects.filter(owner=self.request.user).order_by('income_category_name')
        elif kind == 'Ausgabe':
            outgoing_categories = Outgoingcategory.objects.filter(owner=self.request.user).order_by('outgoing_category_name')
        # Datum von heute vor einem Jahr berechnen
        start_date = timezone.now() - timedelta(days=365)
        
        # Transaktionen der letzten 52 Wochen abrufen und nach Datum sortieren
        transactions = Transaction.objects.filter(date__gte=start_date,transactionkind=kind,owner=self.request.user).order_by('date')
        
        # Liste der Wochen mit den entsprechenden Daten erstellen
        weekly_data = []
        current_week = None
        for transaction in transactions:
            # Woche des aktuellen Transactions berechnen
            week = transaction.date.strftime('%U')
            
            # Wenn Woche wechselt, ein neues Dictionary hinzufügen
            if week != current_week:
                current_week = week
                weekly_data.append({
                    'Woche': week,
                })
                # Für jede Einkommenskategorie ein Feld in das aktuelle Dictionary hinzufügen
                if kind == 'Einnahme':
                    for category in income_categories:
                        weekly_data[-1][category.income_category_name] = 0
                elif kind == 'Ausgabe':
                    for category in outgoing_categories:
                        weekly_data[-1][category.outgoing_category_name] = 0
            
            # Betrag des aktuellen Transactions zum entsprechenden Feld hinzufügen
            if kind == 'Einnahme':
                for category in income_categories:
                    if transaction.category == category.income_category_name:
                        weekly_data[-1][category.income_category_name] += transaction.amount
            elif kind == 'Ausgabe':
                for category in outgoing_categories:
                    if transaction.category == category.outgoing_category_name:
                        weekly_data[-1][category.outgoing_category_name] += transaction.amount
    
        return weekly_data


    def get(self, request, kind, format=None):
        if kind == 'Budget':
            pass
        else:
            result = self.income_transaction_list(self, kind)
        return Response(result)

class FixedTransactionList(APIView):

    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]
    
    def get(self, request, format=None):
        fixedtransaction = FixedTransaction.objects.filter(owner=self.request.user).order_by('-start_date')
        serializer = FixedTransactionSerializer(fixedtransaction, many=True)
        return Response(serializer.data)
    
    def post(self, request, format=None):
        serializer = FixedTransactionSerializer(data=request.data, context={'request': request})
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class FixedTransactionDetail(APIView):
    """
    Retrieve, update or delete a snippet instance.
    """
    def get_object(self, pk):
        try:
            return FixedTransaction.objects.get(pk=pk)
        except FixedTransaction.DoesNotExist:
            raise Http404

    def get_object_without(self, data):
        try:
            return FixedTransaction.objects.get(category=data.get('category'), description=data.get('description'), account=data.get('account'), start_date=data.get('start_date'), yearly_rate=data.get('yearly_rate'), pay_rythm=data.get('pay_rythm'), owner=self.request.user)
        except Transaction.DoesNotExist:
            raise Http404

    def get(self, request, pk, format=None):
        fixedtransaction = self.get_object(pk)
        serializer = FixedTransactionSerializer(fixedtransaction, context={'request': request})
        return Response(serializer.data)

    def put(self, request, pk, format=None):
        fixedtransaction = self.get_object(pk)
        serializer = FixedTransactionSerializer(fixedtransaction, data=request.data, context={'request': request})
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, pk, format=None):
        try:
            pk = int(pk)
            if(pk==-1):
                fixedtransaction = self.get_object_without(json.loads(request.body))
            else:
                fixedtransaction = self.get_object(pk)
            fixedtransaction.delete()
            return Response(status=status.HTTP_204_NO_CONTENT)
        except ValueError:
                return Response(status=status.HTTP_400_BAD_REQUEST)

class AccountList(APIView):

    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]

    def get(self, request, format=None):
        #Wrong
        accounts = Account.objects.filter(owner=self.request.user).order_by('account_name')
        serializer = AccountSerializer(accounts, many=True)
        return Response(serializer.data)

    def post(self, request, format=None):
        serializer = AccountSerializer(data=request.data, context={'request': request})
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
class AccountDetail(APIView):
    """
    Retrieve, update or delete a snippet instance.
    """
    def get_object_without(self, data):
        try:
            return Account.objects.get(account_name=data.get('account_name'), account_amount=data.get('account_amount'))
        except Account.DoesNotExist:
            raise Http404
        
    def get_object(self, pk):
        try:
            return Account.objects.get(pk=pk, owner=self.request.user)
        except Account.DoesNotExist:
            raise Http404

    def get(self, request, pk, format=None):
        account = self.get_object(pk)
        serializer = AccountSerializer(account, context={'request': request})
        return Response(serializer.data)

    def put(self, request, pk, format=None):
        account = self.get_object(pk)
        serializer = AccountSerializer(account, data=request.data, context={'request': request})
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, pk, format=None):
        try:
            pk = int(pk)
            if pk==-1:
                account = self.get_object_without(json.loads(request.body))
            else:
                account = self.get_object(pk)

            account.delete()
            return Response(status=status.HTTP_204_NO_CONTENT)
        except ValueError:
            return Response(status=status.HTTP_400_BAD_REQUEST)

class TransactionList(APIView):

    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]
    
    def get(self, request, format=None):
        transactions = Transaction.objects.filter(owner=self.request.user).order_by('-date')
        serializer = TransactionSerializer(transactions, many=True)
        return Response(serializer.data)
    
    def post(self, request, format=None):
        serializer = TransactionSerializer(data=request.data, context={'request': request})
        if serializer.is_valid():
            serializer.save()
            account = Account.objects.get(account_name=serializer.validated_data['account'], owner=request.user)
            transaction_kind = serializer.validated_data['transactionkind']
            amount = serializer.validated_data['amount']
            if transaction_kind == 'Ausgabe':
                account.account_amount -= amount
            elif transaction_kind == 'Einnahme':
                account.account_amount += amount
            account.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class TransactionDetail(APIView):
    """
    Retrieve, update or delete a snippet instance.
    """
    def get_object(self, pk):
        try:
            return Transaction.objects.get(pk=pk, owner=self.request.user)
        except Transaction.DoesNotExist:
            raise Http404

    def get_object_without(self, data):
        try:
            return Transaction.objects.get(category=data.get('category'), description=data.get('description'), account=data.get('account'), date=data.get('date'), amount=data.get('amount'), owner=self.request.user)
        except Transaction.DoesNotExist:
            raise Http404

    def get(self, request, pk, format=None):
        transaction = self.get_object(pk)
        serializer = TransactionSerializer(transaction, context={'request': request})
        return Response(serializer.data)

    def put(self, request, pk, format=None):
        transaction = self.get_object(pk)
        old_account = transaction.account
        old_amount = transaction.amount
        serializer = TransactionSerializer(transaction, data=request.data, context={'request': request})
        if serializer.is_valid():
            serializer.save()
            new_account = serializer.validated_data['account']
            amount = serializer.validated_data['amount']
            if old_account != new_account:
                old_account_obj = Account.objects.get(account_name=old_account, owner=self.request.user)
                new_account_obj = Account.objects.get(account_name=new_account, owner=self.request.user)
                if serializer.validated_data['transactionkind'] == 'Ausgabe':
                    old_account_obj.account_amount += old_amount
                    new_account_obj.account_amount -= amount
                elif serializer.validated_data['transactionkind'] == 'Einnahme':
                    old_account_obj.account_amount -= old_amount
                    new_account_obj.account_amount += amount
                old_account_obj.save()
                new_account_obj.save()
            else:
                account_obj = Account.objects.get(account_name=new_account, owner=self.request.user)
                if serializer.validated_data['transactionkind'] == 'Ausgabe':
                    account_obj.account_amount -= amount
                    account_obj.account_amount += old_amount
                elif serializer.validated_data['transactionkind'] == 'Einnahme':
                    account_obj.account_amount += amount
                    account_obj.account_amount -= old_amount
                account_obj.save()
            return Response(serializer.data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, pk, format=None):
        try:
            pk = int(pk)
            if(pk==-1):
                transaction = self.get_object_without(json.loads(request.body))
            else:
                transaction = self.get_object(pk=pk)
            account = Account.objects.get(account_name=transaction.account, owner=request.user)
            if transaction.transactionkind == 'Ausgabe':
                account.account_amount += transaction.amount
            elif transaction.transactionkind == 'Einnahme':
                account.account_amount -= transaction.amount
            account.save()
            transaction.delete()
            return Response(status=status.HTTP_204_NO_CONTENT)
        except ValueError:
                    return Response(status=status.HTTP_400_BAD_REQUEST)

class OutgoingCategoryList(APIView):

    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]

    def get(self, request, format=None):
        outgoingcategory = Outgoingcategory.objects.filter(owner=self.request.user).order_by('outgoing_category_name')

        serializer = OutgoingCategorySerializer(outgoingcategory, many=True)
        data = serializer.data

        for item in data:
            transactions = Transaction.objects.filter(owner=request.user, category=item['outgoing_category_name'], date__year=date.today().year, transactionkind='Ausgabe')
            expenses = transactions.annotate(amount_float=Cast('amount', FloatField())).aggregate(Sum('amount_float'))['amount_float__sum'] or 0
            item['expenses'] = str(expenses)
            item['sum'] = str(float(item['budget'])-expenses)

        return Response(data)
    
   
    def post(self, request, format=None):
       serializer = OutgoingCategorySerializer(data=request.data, context={'request': request})
       if serializer.is_valid():
           serializer.save()
           return Response(serializer.data, status=status.HTTP_201_CREATED)
       return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class OutgoingCategoryDetail(APIView):
    """
    Retrieve, update or delete a snippet instance.
    """
    def get_object(self, pk):
        try:
            return Outgoingcategory.objects.get(pk=pk)
        except Outgoingcategory.DoesNotExist:
            raise Http404
        
    def get_object_without(self, data):
        try:
            return Outgoingcategory.objects.get(outgoing_category_name=data.get('outgoing_category_name'), budget=data.get('budget'), owner=self.request.user)
        except Outgoingcategory.DoesNotExist:
            raise Http404

    def get(self, request, pk, format=None):
        outgoingCategory = self.get_object(pk)
        serializer = OutgoingCategorySerializer(outgoingCategory, context={'request': request})
        return Response(serializer.data)

    def put(self, request, pk, format=None):
        outgoingCategory = self.get_object(pk)
        serializer = OutgoingCategorySerializer(outgoingCategory, data=request.data, context={'request': request})
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, pk, format=None):
        try:
            pk = int(pk)
            if(pk==-1):
                outgoingCategory = self.get_object_without(json.loads(request.body))
            else:
                outgoingCategory = self.get_object(pk)
            outgoingCategory.delete()
            return Response(status=status.HTTP_204_NO_CONTENT)
        except ValueError:
                return Response(status=status.HTTP_400_BAD_REQUEST)

class IncomeCategoryList(APIView):

    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]

    def get(self, request, format=None):
        incomecategory = Incomecategory.objects.filter(owner=self.request.user).order_by('income_category_name')
        serializer = IncomeCategorySerializer(incomecategory, many=True)
        return Response(serializer.data)
    
    def post(self, request, format=None):
       serializer = IncomeCategorySerializer(data=request.data, context={'request': request})
       if serializer.is_valid():
           serializer.save()
           return Response(serializer.data, status=status.HTTP_201_CREATED)
       return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class IncomeCategoryDetail(APIView):
    """
    Retrieve, update or delete a snippet instance.
    """
    def get_object(self, pk):
        try:
            return Incomecategory.objects.get(pk=pk)
        except Incomecategory.DoesNotExist:
            raise Http404

    def get_object_without(self, data):
        try:
            return Incomecategory.objects.get(income_category_name=data.get('income_category_name'), owner=self.request.user)
        except Incomecategory.DoesNotExist:
            raise Http404

    def get(self, request, pk, format=None):
        incomeCategory = self.get_object(pk)
        serializer = IncomeCategorySerializer(incomeCategory, context={'request': request})
        return Response(serializer.data)

    def put(self, request, pk, format=None):
        incomeCategory = self.get_object(pk)
        serializer = IncomeCategorySerializer(incomeCategory, data=request.data, context={'request': request})
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, pk, format=None):
        try:
            pk = int(pk)
            if(pk==-1):
                incomeCategory = self.get_object_without(json.loads(request.body))
            else:
                incomeCategory = self.get_object(pk)
            incomeCategory.delete()
            return Response(status=status.HTTP_204_NO_CONTENT)
        except ValueError:
                return Response(status=status.HTTP_400_BAD_REQUEST)
