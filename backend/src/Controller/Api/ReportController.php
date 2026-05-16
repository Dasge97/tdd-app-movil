<?php

declare(strict_types=1);

namespace App\Controller\Api;

use App\Entity\UserReport;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

#[Route('/api/v1')]
class ReportController extends AbstractController
{
    public function __construct(private readonly EntityManagerInterface $em) {}

    #[Route('/debates/{id}/report', name: 'api_debate_report', methods: ['POST'], requirements: ['id' => '\d+'])]
    public function reportDebate(int $id, Request $request): JsonResponse
    {
        $user = $request->attributes->get('currentUser');
        if ($user === null) {
            return new JsonResponse(['error' => 'Unauthorized'], Response::HTTP_UNAUTHORIZED);
        }

        $body   = json_decode($request->getContent(), true) ?? [];
        $reason = isset($body['reason']) ? mb_substr((string) $body['reason'], 0, 255) : null;

        $report = new UserReport($user, 'debate', $id, $reason);
        $this->em->persist($report);
        $this->em->flush();

        return new JsonResponse(null, Response::HTTP_NO_CONTENT);
    }

    #[Route('/comments/{id}/report', name: 'api_comment_report', methods: ['POST'], requirements: ['id' => '\d+'])]
    public function reportComment(int $id, Request $request): JsonResponse
    {
        $user = $request->attributes->get('currentUser');
        if ($user === null) {
            return new JsonResponse(['error' => 'Unauthorized'], Response::HTTP_UNAUTHORIZED);
        }

        $body   = json_decode($request->getContent(), true) ?? [];
        $reason = isset($body['reason']) ? mb_substr((string) $body['reason'], 0, 255) : null;

        $report = new UserReport($user, 'comment', $id, $reason);
        $this->em->persist($report);
        $this->em->flush();

        return new JsonResponse(null, Response::HTTP_NO_CONTENT);
    }
}
