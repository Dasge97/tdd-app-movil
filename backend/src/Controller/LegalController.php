<?php

namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

#[Route('')]
class LegalController extends AbstractController
{
    private const LAST_UPDATED = '16 de mayo de 2025';

    #[Route('/legal/privacidad', name: 'legal_privacidad', methods: ['GET'])]
    public function privacidad(): Response
    {
        return $this->render('legal/privacidad.html.twig', [
            'lastUpdated' => self::LAST_UPDATED,
        ]);
    }

    #[Route('/legal/terminos', name: 'legal_terminos', methods: ['GET'])]
    public function terminos(): Response
    {
        return $this->render('legal/terminos.html.twig', [
            'lastUpdated' => self::LAST_UPDATED,
        ]);
    }

    #[Route('/legal/ia', name: 'legal_ia', methods: ['GET'])]
    public function ia(): Response
    {
        return $this->render('legal/ia.html.twig', [
            'lastUpdated' => self::LAST_UPDATED,
        ]);
    }

    #[Route('/soporte', name: 'legal_soporte', methods: ['GET'])]
    public function soporte(): Response
    {
        return $this->render('legal/soporte.html.twig', [
            'lastUpdated' => self::LAST_UPDATED,
        ]);
    }
}
