<?php

namespace App\Notifications;

use App\Models\Issue;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;

class NewIssueNotification extends Notification
{
    use Queueable;

    public function __construct(public Issue $issue)
    {
    }

    public function via(object $notifiable): array
    {
        return ['database'];
    }

    public function toArray(object $notifiable): array
    {
        return [
            'issue_id' => $this->issue->id,
            'message' => 'Kendala baru dilaporkan: ' . $this->issue->report->schedule->checkpoint->name,
        ];
    }
}
