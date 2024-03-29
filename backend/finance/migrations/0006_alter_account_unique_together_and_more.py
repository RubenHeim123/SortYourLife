# Generated by Django 4.1.3 on 2023-05-09 17:11

from django.conf import settings
from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ('finance', '0005_remove_fixedtransaction_end_date'),
    ]

    operations = [
        migrations.AlterUniqueTogether(
            name='account',
            unique_together={('account_name', 'owner')},
        ),
        migrations.AlterUniqueTogether(
            name='incomecategory',
            unique_together={('income_category_name', 'owner')},
        ),
        migrations.AlterUniqueTogether(
            name='outgoingcategory',
            unique_together={('outgoing_category_name', 'owner')},
        ),
    ]
