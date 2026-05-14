<?php

declare(strict_types=1);

namespace App\Controller\Api;

use App\Entity\Debate;
use App\Entity\User;
use App\Repository\UserRepository;
use App\Serializer\UserNormalizer;
use App\Service\DebateService;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\Routing\Attribute\Route;

#[Route('/api/v1/personas')]
class PersonaController extends AbstractController
{
    public function __construct(
        private readonly UserRepository $userRepository,
        private readonly UserNormalizer $userNormalizer,
        private readonly DebateService $debateService
    ) {
    }

    #[Route('', name: 'api_personas_list', methods: ['GET'])]
    public function list(): JsonResponse
    {
        $personas = $this->userRepository->findAiPersonas();
        return new JsonResponse($this->userNormalizer->normalizeMany($personas));
    }

    #[Route('/{username}/debates', name: 'api_personas_debates', methods: ['GET'])]
    public function debates(string $username, Request $request): JsonResponse
    {
        $page = max(1, (int) $request->query->get('page', '1'));
        $debates = $this->debateService->getPersonaDebates($username, $page);

        return new JsonResponse(
            array_map(fn(Debate $d) => $this->normalizeDebate($d), $debates)
        );
    }

    private function normalizeDebate(Debate $debate): array
    {
        return [
            'id'          => $debate->getId(),
            'title'       => $debate->getTitle(),
            'question'    => $debate->getQuestion(),
            'cardSummary' => $debate->getCardSummary(),
            'dayDate'     => $debate->getDayDate()->format('Y-m-d'),
            'createdAt'   => $debate->getCreatedAt()->format(\DateTimeInterface::ATOM),
        ];
    }
}
