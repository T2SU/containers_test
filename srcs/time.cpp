/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   time.cpp                                           :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: smun <smun@student.42seoul.kr>             +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2022/01/30 21:33:51 by smun              #+#    #+#             */
/*   Updated: 2022/01/30 21:45:36 by smun             ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include <sys/time.h>
#include <iostream>

static time_t	GetTimeMicroseconds()
{
	struct timeval		t;

	gettimeofday(&t, NULL);
	return (t.tv_sec * 1000000 + t.tv_usec);
}

int main(void)
{
	std::cout << GetTimeMicroseconds() << std::endl;
	return 0;
}
