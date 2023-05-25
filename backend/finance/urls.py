from django.urls import path, include
from . import views
from rest_framework import routers

urlpatterns = [
    path('users/', views.UserList.as_view()),
    path('users/create/', views.register, name='register'),
    path('users/checkToken/', views.checkToken, name='checkToken'),
    path('users/checkBackendStatus/', views.checkBackendStatus, name='checkBackendStatus'),
    path('users/<int:pk>/', views.UserDetail.as_view()),
    path('cumulatedTransactions/<str:kind>', views.cumulatedTransactions.as_view(), name='cumulatedTransaction'),
    path('accountsdetails/',views.AccountList.as_view()),
    path('accountsdetails/<str:pk>', views.AccountDetail.as_view()),
    path('transactionsdetails/',views.TransactionList.as_view()),
    path('transactionsdetails/<str:pk>', views.TransactionDetail.as_view()),
    path('fixedtransactionsdetails/',views.FixedTransactionList.as_view()),
    path('fixedtransactionsdetails/<str:pk>', views.FixedTransactionDetail.as_view()),
    path('outgoingcategorysdetails/',views.OutgoingCategoryList.as_view()),
    path('outgoingcategorysdetails/<str:pk>', views.OutgoingCategoryDetail.as_view()),
    path('incomecategorysdetails/',views.IncomeCategoryList.as_view()),
    path('incomecategorysdetails/<str:pk>', views.IncomeCategoryDetail.as_view()),
    path('hello/', views.MyView.as_view()),
]
