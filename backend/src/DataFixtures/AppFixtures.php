<?php

declare(strict_types=1);

namespace App\DataFixtures;

use App\Entity\User;
use Doctrine\Bundle\FixturesBundle\Fixture;
use Doctrine\Persistence\ObjectManager;

class AppFixtures extends Fixture
{
    public function load(ObjectManager $manager): void
    {
        // Cuenta demo para revisión de Google Play / App Store
        $existing = $manager->getRepository(User::class)->findOneBy(['username' => 'demo']);
        if ($existing === null) {
            $demo = new User();
            $demo->setUsername('demo');
            $demo->setEmail('demo@tudebatediario.com');
            $demo->setPasswordHash(password_hash('Demo1234!', PASSWORD_BCRYPT));
            $demo->setRole('user');
            $demo->setStatus('active');
            $demo->setBio('Cuenta de demostración para revisión de la tienda.');
            $manager->persist($demo);
        }

        $manager->flush();
    }
}
