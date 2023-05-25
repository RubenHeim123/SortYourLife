from django.contrib import admin
from .models import *

# Register your models here.
admin.site.register(FixedTransaction)
admin.site.register(Transaction)
admin.site.register(Outgoingcategory)
admin.site.register(Incomecategory)
admin.site.register(Account)