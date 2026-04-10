from django.db import migrations


def create_centers(apps, schema_editor):
    DonationCenter = apps.get_model("appointments", "DonationCenter")
    DonationCenter.objects.bulk_create([
        DonationCenter(
            name="Hospital Clínico UC",
            address="Marcoleta 367",
            comuna="Santiago",
            phone="+56 2 2354 3000"
        ),
        DonationCenter(
            name="Hospital del Salvador",
            address="Av Salvador 364",
            comuna="Providencia",
            phone="+56 2 2575 5000"
        ),
        DonationCenter(
            name="Clínica Alemana",
            address="Av Vitacura 5951",
            comuna="Vitacura",
            phone="+56 2 2210 1111"
        ),
        DonationCenter(
            name="Hospital San José",
            address="Av Independencia 711",
            comuna="Independencia",
            phone="+56 2 2576 7000"
        ),
        DonationCenter(
            name="Hospital Sótero del Río",
            address="Av Concha y Toro 3459",
            comuna="Puente Alto",
            phone="+56 2 2576 8000"
        ),
        DonationCenter(
            name="Hospital Félix Bulnes",
            address="Av Mapocho 8481",
            comuna="Cerro Navia",
            phone="+56 2 2575 9000"
        ),
        DonationCenter(
            name="Clínica Santa María",
            address="Av Santa María 0500",
            comuna="Providencia",
            phone="+56 2 2913 0000"
        ),
        DonationCenter(
            name="Hospital Militar",
            address="Av Fernando Castillo Velasco 9100",
            comuna="La Reina",
            phone="+56 2 2976 1111"
        ),
        DonationCenter(
            name="Clínica Dávila",
            address="Av Recoleta 464",
            comuna="Recoleta",
            phone="+56 2 2730 8000"
        ),
        DonationCenter(
            name="Clínica Indisa",
            address="Av Santa María 1810",
            comuna="Providencia",
            phone="+56 2 2362 5555"
        ),
    ])


def delete_centers(apps, schema_editor):
    DonationCenter = apps.get_model("appointments", "DonationCenter")
    DonationCenter.objects.filter(
        name__in=[
            "Hospital Clínico UC",
            "Hospital del Salvador",
            "Clínica Alemana",
            "Hospital San José",
            "Hospital Sótero del Río",
            "Hospital Félix Bulnes",
            "Clínica Santa María",
            "Hospital Militar",
            "Clínica Dávila",
            "Clínica Indisa",
        ]
    ).delete()


class Migration(migrations.Migration):

    dependencies = [
        ("appointments", "0001_initial"),
    ]

    operations = [
        migrations.RunPython(create_centers, delete_centers),
    ]
