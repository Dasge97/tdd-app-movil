<?php

namespace App\Controller;

use App\Repository\UserRepository;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

class HomeController extends AbstractController
{
    private const PLAY_STORE_URL = 'https://play.google.com/store/apps/details?id=com.tudebatediario.app';

    public function __construct(private readonly UserRepository $userRepository) {}

    #[Route('/', name: 'landing', methods: ['GET'])]
    public function index(): Response
    {
        $personas = $this->userRepository->findAiPersonas();

        return $this->render('landing/index.html.twig', [
            'personas'     => $personas,
            'playStoreUrl' => self::PLAY_STORE_URL,
        ]);
    }
}
